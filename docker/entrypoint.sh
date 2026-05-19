#!/usr/bin/env bash
set -e

source "/opt/ros/${ROS_DISTRO}/setup.bash"

if [ -f "/home/${USER}/ros2_ws/install/setup.bash" ]; then
    source "/home/${USER}/ros2_ws/install/setup.bash"
fi

# If invoked with no command (or a single empty-string arg), drop into bash.
if [ "$#" -eq 0 ] || { [ "$#" -eq 1 ] && [ -z "$1" ]; }; then
    exec bash
fi

exec "$@"
