#!/usr/bin/env bash
# Add the current user to the docker group so docker.sock is readable
# without sudo. After this runs you need a NEW shell (or `newgrp docker`)
# for the change to take effect.
#
# Idempotent: safe to run repeatedly.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

TARGET_USER="${SUDO_USER:-${USER}}"

if id -nG "${TARGET_USER}" | tr ' ' '\n' | grep -qx docker; then
    ok "${TARGET_USER} is already in the docker group."
    log "If 'docker ps' still fails, open a new terminal (group changes don't"
    log "  affect already-running shells). You can also run: newgrp docker"
    exit 0
fi

if ! getent group docker >/dev/null; then
    err "No 'docker' group on this system. Is Docker installed?"
    exit 1
fi

log "Adding ${TARGET_USER} to the docker group (requires sudo)..."
sudo usermod -aG docker "${TARGET_USER}"
ok "Done. Group change applies in NEW shells only."
log "To activate in this shell right now, run: newgrp docker"
log "Then verify with: docker ps"
