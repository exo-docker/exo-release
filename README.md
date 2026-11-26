# exo-release

Docker images used to release eXo Platform components. Each image bundles a JDK + Maven toolchain
(from [`exoplatform/ci`](https://hub.docker.com/r/exoplatform/ci)) with the
[eXo Release Manager](https://github.com/exoplatform/swf-release-manager) (`eXoR`), `jq` and `yq`.
The images are published as `exoplatform/release:<jdk>-<maven>[-<os>]` and run by the Jenkins
release jobs.

## Layout

| Path | Purpose |
|---|---|
| `Dockerfile` | the single, parameterised Dockerfile (`BASE_IMAGE` selects the toolchain) |
| `images.json` | every published tag, with its optional extra build arguments |
| `build.sh` | builds one, several or all images from `images.json` |
| `legacy/` | two frozen images (`jdk7-maven30`, `jdk8-maven30`) that also bundle Tomcat/JBoss for GateIn |
| `.github/workflows/ci.yml` | hadolint, shellcheck, build + smoke test of the images |

## Building

```sh
./build.sh --list                     # available tags
./build.sh jdk17-maven39              # one image  -> exoplatform/release:jdk17-maven39
./build.sh smoke                      # the representative subset CI builds
./build.sh all                        # everything
./build.sh -n jdk21-maven310-ubuntu26 # print the docker command only
```

The base image of tag `T` is `exoplatform/ci:T`.

### Build arguments

| Argument | Default | Meaning |
|---|---|---|
| `BASE_IMAGE` | `exoplatform/ci:jdk17-maven39` | toolchain image (set by `build.sh`) |
| `EXOR_VERSION` | a release tag | swf-release-manager **tag or branch** to install |
| `JQ_VERSION`, `JQ_SHA256` | | `jq` release and its sha256 |
| `YQ_VERSION`, `YQ_SHA256` | | `yq` release and its sha256 (reads YAML catalogs) |
| `EXTRA_MAVEN_OPTS` | empty | appended to `MAVEN_OPTS` (old GateIn builds need `-Dservers.dir=...`) |
| `ssh_passphrase`, `nexus_token`, `gpg_passphrase`, `jira_auth_header`, `jboss_password` | `default` | credentials stored (base64) in the image by the Jenkins build |

`jq` and `yq` are downloaded and verified against their sha256: a mismatch fails the build. When you
bump `JQ_VERSION`/`YQ_VERSION`, update the matching `*_SHA256` from the upstream checksum files.

## Testing a branch of the Release Manager

`EXOR_VERSION` accepts any tag **or branch**, so a change can be tried before it is released:

```sh
./build.sh -r rework jdk17-maven39    # -> exoplatform/release:jdk17-maven39 built from the branch
```

The branch is downloaded at build time: rebuild to pick up new commits. Tag such an image
differently (`-i exoplatform/release-dev`) so it is never pushed under a release tag.

## Releasing a new Release Manager version

Bump the `EXOR_VERSION` default in `Dockerfile` (one place), then rebuild and publish the images.

## CI

Pull requests run hadolint on the Dockerfiles, shellcheck on `build.sh`, and build + smoke-test
(`help`, `git`, `mvn`, `jq`) the `smoke` images. Run the workflow manually to build `all` images or
a given list, optionally against a Release Manager branch.
