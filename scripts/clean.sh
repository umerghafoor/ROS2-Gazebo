#!/usr/bin/env bash
# Remove the image and any leftover containers. Does NOT touch ./workspace.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

bash "${SCRIPT_DIR}/stop.sh" || true

for tag in "${IMAGE_TAG}" latest; do
    if docker image inspect "${IMAGE_NAME}:${tag}" >/dev/null 2>&1; then
        log "Removing image ${IMAGE_NAME}:${tag}"
        docker rmi "${IMAGE_NAME}:${tag}" || true
    fi
done

ok "Clean complete."
