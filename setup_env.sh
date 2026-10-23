#!/usr/bin/env bash
# 我的 ROS 2 工作空间环境脚本
# 用法: source ~/g1d_ros2_lzh/setup_env.sh
#
# 关键点:
#   1) 先 source 系统 ROS, 再 source 我的 overlay —— 顺序不能反
#   2) 设 ROS_DOMAIN_ID=42, 与师兄的 domain 0 隔离
#   3) 绝不 source 师兄的 g1d_ros2_ws

export ROS_DOMAIN_ID=42

source /opt/ros/humble/setup.bash
source "$HOME/g1d_ros2_lzh/install/setup.bash"

echo "ROS_DOMAIN_ID = $ROS_DOMAIN_ID"
echo "工作空间: $HOME/g1d_ros2_lzh"
