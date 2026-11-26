#!/bin/bash
# Build the exoplatform/release images described in images.json.
set -euo pipefail
cd "$(dirname "$0")"

IMAGE=${IMAGE:-exoplatform/release}
DRY_RUN=0
EXOR_REF=""

usage() {
  cat <<USAGE
Usage: $0 [-n] [-r EXOR_REF] [-i IMAGE] [--list] <tag>... | all | smoke

  <tag>      image tags from images.json (e.g. jdk17-maven39)
  all        every image;  smoke: the representative subset built by CI
  -r REF     swf-release-manager tag or branch to install (default: the Dockerfile's EXOR_VERSION)
  -i IMAGE   image name (default: ${IMAGE})
  -n         print the docker commands without running them
  --list     list the available tags
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n) DRY_RUN=1 ;;
    -r) EXOR_REF=${2:?-r needs a value}; shift ;;
    -i) IMAGE=${2:?-i needs a value}; shift ;;
    --list) jq -r '.[].tag' images.json; exit 0 ;;
    -h | --help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
  shift
done
[ $# -gt 0 ] || { usage >&2; exit 2; }

tags=()
for arg in "$@"; do
  case "$arg" in
    all) while IFS= read -r t; do tags+=("$t"); done < <(jq -r '.[].tag' images.json) ;;
    smoke) while IFS= read -r t; do tags+=("$t"); done < <(jq -r '.[] | select(.smoke) | .tag' images.json) ;;
    *) tags+=("$arg") ;;
  esac
done

for tag in "${tags[@]}"; do
  entry=$(jq -c --arg t "$tag" '.[] | select(.tag == $t)' images.json)
  [ -n "$entry" ] || { echo "Unknown tag: $tag (see --list)" >&2; exit 2; }
  dockerfile=$(jq -r '.dockerfile // "Dockerfile"' <<<"$entry")
  cmd=(docker build -f "$dockerfile" -t "${IMAGE}:${tag}")
  if [ "$dockerfile" = "Dockerfile" ]; then
    cmd+=(--build-arg "BASE_IMAGE=exoplatform/ci:${tag}")
  fi
  while IFS= read -r kv; do cmd+=(--build-arg "$kv"); done \
    < <(jq -r '.build_args // {} | to_entries[] | "\(.key)=\(.value)"' <<<"$entry")
  [ -n "$EXOR_REF" ] && cmd+=(--build-arg "EXOR_VERSION=${EXOR_REF}")
  cmd+=(.)
  if [ "$DRY_RUN" = 1 ]; then printf '%q ' "${cmd[@]}"; echo; else "${cmd[@]}"; fi
done
