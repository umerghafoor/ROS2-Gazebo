#!/usr/bin/env bash
# Open another bash shell in the running container.
# Useful when you've already started Gazebo in one terminal and want a second
# session for ros2 commands without restarting anything.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

NAME="${1:-${CONTAINER_NAME}}"

if ! docker ps --format '{{.Names}}' | grep -qx "${NAME}"; then
    err "Container '${NAME}' is not running. Start it with ./scripts/run.sh"
    exit 1
fi

exec docker exec -it "${NAME}" bash
