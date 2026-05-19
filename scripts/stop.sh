#!/usr/bin/env bash
# Stop and remove the container.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

NAME="${1:-${CONTAINER_NAME}}"

if docker ps --format '{{.Names}}' | grep -qx "${NAME}"; then
    log "Stopping ${NAME}"
    docker stop "${NAME}" >/dev/null
fi

if docker ps -a --format '{{.Names}}' | grep -qx "${NAME}"; then
    log "Removing ${NAME}"
    docker rm "${NAME}" >/dev/null
fi

ok "Container ${NAME} stopped."
