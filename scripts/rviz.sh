#!/usr/bin/env bash
# Launch RViz2 inside the container.
#
# Usage:
#   ./scripts/rviz.sh                          # default config (TF, Grid, common displays)
#   ./scripts/rviz.sh -d /path/to/config.rviz  # custom config path (inside container)
#
# If the ros2-gazebo container is already running, RViz is exec'd into it so
# it shares the same ROS_DOMAIN_ID and can see topics published by Gazebo /
# the bridge. Otherwise a fresh container is started.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=setup_x11.sh
source "${SCRIPT_DIR}/setup_x11.sh"

setup_x11

DEFAULT_CFG="/home/ros/.rviz2/default.rviz"

# If user didn't pass -d / --display-config, prepend our default.
ARGS=("$@")
USE_DEFAULT=1
for a in "${ARGS[@]:-}"; do
    case "$a" in
        -d|--display-config) USE_DEFAULT=0;;
    esac
done
if [ "${USE_DEFAULT}" -eq 1 ]; then
    ARGS=(-d "${DEFAULT_CFG}" "${ARGS[@]}")
fi

# Reuse the running container so RViz shares the DDS domain with Gazebo / bridges.
if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    log "Attaching RViz to running container ${CONTAINER_NAME}"
    exec docker exec -it "${CONTAINER_NAME}" rviz2 "${ARGS[@]}"
fi

log "No running container — starting a fresh one for RViz"
exec "${SCRIPT_DIR}/run.sh" --name ros2-gazebo-rviz rviz2 "${ARGS[@]}"
