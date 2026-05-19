#!/usr/bin/env bash
# Configure X11 forwarding so GUI apps (Gazebo, RViz, rqt) work from inside
# the container. Safe to source or execute. Idempotent.
#
# What this fixes:
#   - "Authorization required, but no authorization protocol specified"
#   - "cannot open display"
#   - Qt / OpenGL apps crashing on launch
#
# Strategy: build a per-session xauth cookie at /tmp/.docker.xauth that
# accepts connections from any host (FamilyWild) and bind-mount it into
# the container along with the X11 unix socket.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

XAUTH_FILE="${XAUTH_FILE:-/tmp/.docker.xauth}"

setup_x11() {
    if [ -z "${DISPLAY:-}" ]; then
        warn "DISPLAY is not set. GUI apps will not work."
        warn "If you are on a headless server, set DISPLAY=:0 and run an X server, or use xpra/VNC."
        return 0
    fi

    log "Configuring X11 forwarding for DISPLAY=${DISPLAY}"

    # Loosen access control so the container's user can connect.
    # `xhost +local:docker` is the narrow form; +local: works for any local user
    # which is what we need when the container UID differs from the host.
    if command -v xhost >/dev/null 2>&1; then
        xhost +local:docker >/dev/null 2>&1 || xhost +local: >/dev/null 2>&1 || true
    else
        warn "xhost not installed — install x11-xserver-utils for best results."
    fi

    # Create xauth cookie file the container can read.
    rm -f "${XAUTH_FILE}"
    touch "${XAUTH_FILE}"

    if command -v xauth >/dev/null 2>&1; then
        # Pull current cookie, rewrite family byte so it works across hosts/uids.
        local cookie
        cookie="$(xauth nlist "${DISPLAY}" 2>/dev/null | sed -e 's/^..../ffff/' || true)"
        if [ -n "${cookie}" ]; then
            echo "${cookie}" | xauth -f "${XAUTH_FILE}" nmerge - >/dev/null 2>&1 || true
        else
            warn "Could not read an xauth cookie for ${DISPLAY}; container may still work via xhost."
        fi
    else
        warn "xauth not installed — install xauth for best results."
    fi

    chmod 644 "${XAUTH_FILE}"

    ok "X11 ready: socket=/tmp/.X11-unix  xauth=${XAUTH_FILE}"
}

# Run when executed directly; do nothing when sourced.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    setup_x11
fi
