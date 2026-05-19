"""Launch Gazebo, the ros_gz bridge, and RViz2 together.

Run inside the container:
    ros2 launch ~/.config/ros2-gazeebo/launch/gz_rviz.launch.py

Args:
    world:     SDF world file or built-in name (default: shapes.sdf)
    rviz_cfg:  path to .rviz config (default: ~/.rviz2/default.rviz)
    bridge:    comma-separated extra topic@ros_type@gz_type bridge specs
"""

import os

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, ExecuteProcess
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node


def generate_launch_description():
    home = os.path.expanduser("~")

    world = LaunchConfiguration("world")
    rviz_cfg = LaunchConfiguration("rviz_cfg")
    bridge_args = LaunchConfiguration("bridge")

    gz_sim = ExecuteProcess(
        cmd=["gz", "sim", "-v", "4", "-r", world],
        output="screen",
    )

    # Always bridge /clock so RViz can use sim time.
    clock_bridge = Node(
        package="ros_gz_bridge",
        executable="parameter_bridge",
        arguments=["/clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock"],
        output="screen",
    )

    # Optional extra bridges supplied via the `bridge` argument.
    extra_bridge = Node(
        package="ros_gz_bridge",
        executable="parameter_bridge",
        arguments=[bridge_args],
        output="screen",
        condition=None,  # Always created; empty args become a no-op bridge.
    )

    rviz = Node(
        package="rviz2",
        executable="rviz2",
        arguments=["-d", rviz_cfg],
        parameters=[{"use_sim_time": True}],
        output="screen",
    )

    return LaunchDescription([
        DeclareLaunchArgument("world", default_value="shapes.sdf"),
        DeclareLaunchArgument(
            "rviz_cfg",
            default_value=os.path.join(home, ".rviz2", "default.rviz"),
        ),
        DeclareLaunchArgument(
            "bridge",
            default_value="",
            description="Extra ros_gz_bridge spec, e.g. '/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist'",
        ),
        gz_sim,
        clock_bridge,
        extra_bridge,
        rviz,
    ])
