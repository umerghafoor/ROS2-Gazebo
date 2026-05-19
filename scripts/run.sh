#!/usr/bin/env bash
# Launch a container from the ROS 2 + Gazebo image.
#
# Usage:
#   ./scripts/run.sh                       # interactive shell
#   ./scripts/run.sh ros2 topic list       # run a one-off command
#   ./scripts/run.sh gz sim shapes.sdf     # open Gazebo with a world
#
# Flags:
#   --name NAME    container name (default: ros2-gazebo)
#   --no-gpu       skip --gpus all even if an NVIDIA GPU is detected
#   --rm / --keep  remove container on exit (default) / keep it
#   --detach       run in background
#
# Environment overrides:
#   IMAGE_NAME, IMAGE_TAG, ROS_DOMAIN_ID

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=setup_x11.sh
source "${SCRIPT_DIR}/setup_x11.sh"

require_cmd docker
check_docker_access

REMOVE_ON_EXIT=1
DETACH=0
FORCE_NO_GPU=0
NAME="${CONTAINER_NAME}"

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)   NAME="$2"; shift 2;;
        --no-gpu) FORCE_NO_GPU=1; shift;;
        --rm)     REMOVE_ON_EXIT=1; shift;;
        --keep)   REMOVE_ON_EXIT=0; shift;;
        --detach|-d) DETACH=1; shift;;
        --) shift; POSITIONAL+=("$@"); break;;
        *)  POSITIONAL+=("$1"); shift;;
    esac
done
set -- "${POSITIONAL[@]}"

if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
    warn "Image ${IMAGE_NAME}:${IMAGE_TAG} not found locally. Building it now…"
    "${SCRIPT_DIR}/build.sh"
fi

# Resolve X11 forwarding before container launch.
setup_x11

GPU_ARGS=()
if [ "${FORCE_NO_GPU}" -eq 0 ] && detect_nvidia; then
    log "NVIDIA GPU detected — enabling --gpus all"
    GPU_ARGS=(--gpus all)
else
    if [ "${FORCE_NO_GPU}" -eq 1 ]; then
        log "GPU disabled by flag — using software rendering"
    else
        warn "No usable NVIDIA GPU/runtime detected — falling back to software rendering"
        warn "  (install nvidia-container-toolkit to enable hardware acceleration)"
    fi
    GPU_ARGS=(--device /dev/dri:/dev/dri)
fi

RUN_FLAGS=(
    --name "${NAME}"
    --hostname "${NAME}"
    --network host
    --ipc host
    -e "DISPLAY=${DISPLAY:-:0}"
    -e "QT_X11_NO_MITSHM=1"
    -e "XAUTHORITY=/tmp/.docker.xauth"
    -e "NVIDIA_VISIBLE_DEVICES=all"
    -e "NVIDIA_DRIVER_CAPABILITIES=all"
    -e "ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}"
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw
    -v /tmp/.docker.xauth:/tmp/.docker.xauth:rw
    -v "${PROJECT_ROOT}/workspace:/home/ros/ros2_ws:rw"
)

# Reuse a running container if one already exists with this name.
if docker ps --format '{{.Names}}' | grep -qx "${NAME}"; then
    log "Container ${NAME} already running — exec'ing into it"
    if [ "$#" -eq 0 ]; then
        exec docker exec -it "${NAME}" bash
    else
        exec docker exec -it "${NAME}" "$@"
    fi
fi

if docker ps -a --format '{{.Names}}' | grep -qx "${NAME}"; then
    log "Removing stopped container ${NAME}"
    docker rm "${NAME}" >/dev/null
fi

MODE_FLAGS=()
if [ "${DETACH}" -eq 1 ]; then
    MODE_FLAGS+=(-d)
else
    MODE_FLAGS+=(-it)
fi
if [ "${REMOVE_ON_EXIT}" -eq 1 ]; then
    MODE_FLAGS+=(--rm)
fi

log "Starting ${IMAGE_NAME}:${IMAGE_TAG} as ${NAME}"
exec docker run \
    "${MODE_FLAGS[@]}" \
    "${RUN_FLAGS[@]}" \
    "${GPU_ARGS[@]}" \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    "$@"
