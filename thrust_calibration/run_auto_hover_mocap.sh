#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/tmux_utils.sh"

SESSION="auto_hover"

echo "nv" | sudo -S chmod 777 /dev/ttyTHS0

fn_tmux_session_start "$SESSION"

fn_tmux_split_h "$SESSION" 0
fn_tmux_split_v "$SESSION" 1

fn_tmux_run "$SESSION" 0 "roslaunch mavros px4.launch fcu_url:='/dev/ttyTHS0:921600'"
fn_tmux_run "$SESSION" 0 "sleep 5"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 31 5000 0 0 0 0 0"
fn_tmux_run "$SESSION" 0 "sleep 1"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 105 5000 0 0 0 0 0"
fn_tmux_run "$SESSION" 0 "sleep 1"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 106 20000 0 0 0 0 0"
fn_tmux_run "$SESSION" 0 "sleep 1"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 147 10000 0 0 0 0 0"
fn_tmux_run "$SESSION" 0 "sleep 1"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 147 5000 0 0 0 0 0"

fn_tmux_run "$SESSION" 1 "sleep 5"
fn_tmux_run "$SESSION" 1 "roslaunch vrpn_client_ros sample.launch server:=10.1.1.198"

fn_tmux_run "$SESSION" 2 "sleep 8"
fn_tmux_run "$SESSION" 2 "until rostopic list | grep -q '/vrpn_client_node'; do sleep 0.5; done"
fn_tmux_run "$SESSION" 2 'bash -lc "source /opt/ros/noetic/setup.bash && source /home/nv/arec_bags/simple_px4_odom/devel/setup.bash && exec roslaunch simple_px4_odom mocap_to_mavros_odom.launch input_pose:=/vrpn_client_node/zuanfeng/pose"'

fn_tmux_attach "$SESSION"
