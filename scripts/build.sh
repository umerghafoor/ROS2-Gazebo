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

DOCKER_BUILDKIT=1 docker build \
    -f docker/Dockerfile \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -t "${IMAGE_NAME}:latest" \
    --build-arg "ROS_DISTRO=${ROS_DISTRO}" \
    --build-arg "GZ_DISTRO=${GZ_DISTRO}" \
    --build-arg "UBUNTU_VERSION=${UBUNTU_VERSION}" \
    --build-arg "USER_UID=$(id -u)" \
    --build-arg "USER_GID=$(id -g)" \
    "$@" \
    .

ok "Built ${IMAGE_NAME}:${IMAGE_TAG}"
