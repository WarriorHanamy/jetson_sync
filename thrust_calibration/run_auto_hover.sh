#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source /opt/ros/noetic/setup.bash
source "$SCRIPT_DIR/tmux_utils.sh"

SESSION="auto_hover"

echo "nv" | sudo -S chmod 777 /dev/ttyTHS0

fn_tmux_session_start "$SESSION"

fn_tmux_run "$SESSION" 0 "roscore &"
fn_tmux_run "$SESSION" 0 "sleep 3"
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

fn_tmux_split_h "$SESSION" 0
fn_tmux_run "$SESSION" 1 "sleep 10"
fn_tmux_run "$SESSION" 1 "roslaunch vrpn_client_ros sample.launch server:=10.1.1.198"
fn_tmux_run "$SESSION" 1 "sleep 2"
fn_tmux_run "$SESSION" 1 "roslaunch ekf_quat nokov.launch"

fn_tmux_split_v "$SESSION" 1
fn_tmux_run "$SESSION" 2 "sleep 14"
fn_tmux_run "$SESSION" 2 "roslaunch /home/nv/arec_bags/thrust_calibration/run_auto_hover.launch"

fn_tmux_attach "$SESSION"
