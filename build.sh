#!/bin/bash
set -euo pipefail

IMAGE_BASE="${IMAGE_BASE:-exoplatform/release}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"

RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { printf "${CYAN}[BUILD]${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}[OK]${RESET} %s\n" "$*"; }
err()  { printf "${RED}[FAIL]${RESET} %s\n" "$*" >&2; }

build_image() {
    local jdk=$1 maven=$2
    shift 2
    local dockerfile="images/${jdk}/${maven}/Dockerfile"
    local tag="${IMAGE_BASE}:${jdk}-${maven}"

    if [ ! -f "$dockerfile" ]; then
        err "Dockerfile not found: ${dockerfile}"
        return 1
    fi

    log "Building ${tag} ..."
    if docker build "$@" -f "${dockerfile}" -t "${tag}" "${BUILD_CONTEXT}"; then
        ok "Built ${tag}"
    else
        err "Failed to build ${tag}"
        return 1
    fi
}

build_jdk() {
    local jdk=$1; shift
    local maven_dirs
    maven_dirs=$(find "images/${jdk}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

    for maven in $maven_dirs; do
        build_image "${jdk}" "${maven}" "$@" || return 1
    done
}

usage() {
    echo "Usage: $0 [options] [jdk] [maven]"
    echo ""
    echo "Build eXo Release Manager Docker images."
    echo ""
    echo "Options:"
    echo "  --push          Push images after building"
    echo "  --no-cache      Build without cache"
    echo "  --list          List available images"
    echo ""
    echo "Examples:"
    echo "  $0                          # Build all images"
    echo "  $0 jdk17                    # Build all jdk17 variants"
    echo "  $0 jdk17 maven39            # Build specific variant"
    echo "  $0 --push jdk17 maven39     # Build and push"
    exit 0
}

main() {
    local push=false
    local docker_args=()
    local pos_args=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --push) push=true; shift ;;
            --no-cache) docker_args+=(--no-cache); shift ;;
            --list)
                find images -mindepth 2 -maxdepth 2 -name Dockerfile | \
                    sed 's|images/||; s|/Dockerfile||' | \
                    awk -F'/' '{printf "  %-20s %s\n", $1, $2}' | sort
                exit 0
                ;;
            --help|-h) usage ;;
            *) pos_args+=("$1"); shift ;;
        esac
    done

    local jdk=${pos_args[0]:-}
    local maven=${pos_args[1]:-}

    if [ -n "$jdk" ] && [ -n "$maven" ]; then
        build_image "${jdk}" "${maven}" "${docker_args[@]}"
    elif [ -n "$jdk" ]; then
        build_jdk "${jdk}" "${docker_args[@]}"
    else
        local jdk_dirs
        jdk_dirs=$(find images -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -t'jdk' -k2 -n)
        for j in $jdk_dirs; do
            build_jdk "${j}" "${docker_args[@]}" || true
        done
    fi

    if $push; then
        log "Pushing images..."
        local images_built
        images_built=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep "^${IMAGE_BASE}:" | sort -u)
        for img in $images_built; do
            log "Pushing ${img} ..."
            docker push "${img}" || err "Failed to push ${img}"
        done
    fi

    ok "Done."
}

main "$@"
