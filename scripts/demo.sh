#!/usr/bin/env bash
# Sanity check: launch Gazebo with the shapes demo world.
# Confirms ROS 2, Gazebo, X11 and (optional) GPU all work end-to-end.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

log "Launching Gazebo Harmonic with shapes.sdf"
log "Close the Gazebo window to exit."
exec "${SCRIPT_DIR}/run.sh" --name ros2-gazebo-demo gz sim -v 4 shapes.sdf
