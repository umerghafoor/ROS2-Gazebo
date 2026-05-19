#!/usr/bin/env bash
# Launch Gazebo + ros_gz bridge + RViz2 together via the bundled launch file.
# This is the recommended sanity check for the full ROS 2 <-> Gazebo loop.
#
# Usage:
#   ./scripts/gz_rviz.sh                       # shapes.sdf + default RViz config
#   ./scripts/gz_rviz.sh world:=empty.sdf      # override the world
#   ./scripts/gz_rviz.sh bridge:='/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist'

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

LAUNCH_FILE="/home/ros/.config/ros2-gazeebo/launch/gz_rviz.launch.py"

log "Launching Gazebo + bridge + RViz (world=shapes.sdf by default)"
exec "${SCRIPT_DIR}/run.sh" --name ros2-gazebo-gzrviz \
    ros2 launch "${LAUNCH_FILE}" "$@"
