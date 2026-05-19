#!/usr/bin/env bash
# Build the ROS 2 + Gazebo Docker image.
#
# Usage:
#   ./scripts/build.sh                  # default jazzy + harmonic
#   ROS_DISTRO=humble GZ_DISTRO=fortress UBUNTU_VERSION=22.04 ./scripts/build.sh
#   ./scripts/build.sh --no-cache       # forwarded to docker build

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_cmd docker

log "Building image ${IMAGE_NAME}:${IMAGE_TAG}"
log "  ROS_DISTRO     = ${ROS_DISTRO}"
log "  GZ_DISTRO      = ${GZ_DISTRO}"
log "  UBUNTU_VERSION = ${UBUNTU_VERSION}"

cd "${PROJECT_ROOT}"

# Resolve UID/GID for the in-container `ros` user.
# If running as root (e.g. via sudo), id -u/-g return 0 — that collides with
# the root group inside the image. Fall back to SUDO_UID/SUDO_GID when
# available, otherwise default to 1000:1000.
BUILD_UID="$(id -u)"
BUILD_GID="$(id -g)"
if [ "${BUILD_UID}" = "0" ]; then
    BUILD_UID="${SUDO_UID:-1000}"
    BUILD_GID="${SUDO_GID:-1000}"
    warn "Running as root — using UID:GID ${BUILD_UID}:${BUILD_GID} for the container user."
    warn "  (Run without sudo once you've added yourself to the 'docker' group.)"
fi

# Prefer BuildKit if the buildx plugin is installed (faster, better cache).
# Some distros (e.g. Ubuntu's docker.io package) ship Docker without buildx —
# fall back to the legacy builder in that case so the build still works.
if docker buildx version >/dev/null 2>&1; then
    export DOCKER_BUILDKIT=1
    log "Using BuildKit (buildx detected)"
else
    export DOCKER_BUILDKIT=0
    warn "buildx not installed — using the legacy builder."
    warn "  For faster builds: sudo apt install docker-buildx (or docker-buildx-plugin)"
fi

docker build \
    -f docker/Dockerfile \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -t "${IMAGE_NAME}:latest" \
    --build-arg "ROS_DISTRO=${ROS_DISTRO}" \
    --build-arg "GZ_DISTRO=${GZ_DISTRO}" \
    --build-arg "UBUNTU_VERSION=${UBUNTU_VERSION}" \
    --build-arg "USER_UID=${BUILD_UID}" \
    --build-arg "USER_GID=${BUILD_GID}" \
    "$@" \
    .

ok "Built ${IMAGE_NAME}:${IMAGE_TAG}"
