#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/tmux_utils.sh"

SESSION="auto_hover"

echo "nv" | sudo -S chmod 777 /dev/ttyTHS0

fn_tmux_session_start "$SESSION"

fn_tmux_split_h "$SESSION" 0
fn_tmux_split_v "$SESSION" 0
fn_tmux_split_v "$SESSION" 1

fn_tmux_run "$SESSION" 0 "roslaunch mavros px4.launch fcu_url:='/dev/ttyTHS0:921600' gcs_url:='udp://@192.168.110.229:14550'"
fn_tmux_run "$SESSION" 0 "sleep 5"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 31 5000 0 0 0 0 0" # ATTITUDE QUATERNION
fn_tmux_run "$SESSION" 0 "sleep 1"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 105 4000 0 0 0 0 0" # HIGHRES IMU
fn_tmux_run "$SESSION" 0 "sleep 1"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 106 20000 0 0 0 0 0"
fn_tmux_run "$SESSION" 0 "sleep 1"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 147 10000 0 0 0 0 0"
fn_tmux_run "$SESSION" 0 "sleep 1"
fn_tmux_run "$SESSION" 0 "rosrun mavros mavcmd long 511 147 5000 0 0 0 0 0"


fn_tmux_run "$SESSION" 1 'bash -lc "source /opt/ros/noetic/setup.bash && source /home/nv/Fast-Drone-250-master/devel/setup.bash && exec roslaunch realsense2_camera rs_camera.launch infra_width:=640 infra_height:=480 enable_infra1:=true enable_infra2:=true enable_depth:=true enable_color:=false"'

fn_tmux_run "$SESSION" 2 "until rostopic list | grep -q '/mavros/state' && rostopic list | grep -q '/camera'; do sleep 0.5; done"


fn_tmux_run "$SESSION" 2 'bash -lc "source /opt/ros/noetic/setup.bash && source /home/nv/Fast-Drone-250-master/devel/setup.bash && exec roslaunch vins fast_drone_250.launch"'


fn_tmux_run "$SESSION" 3 "sleep 1"
fn_tmux_run "$SESSION" 3 "until rostopic list | grep -q '/vins_fusion/imu_propagate'; do sleep 0.5; done"
fn_tmux_run "$SESSION" 3 'bash -lc "source /opt/ros/noetic/setup.bash && source /home/nv/arec_bags/simple_px4_odom/devel/setup.bash && exec roslaunch simple_px4_odom vio_to_mavros_odom.launch input_odom:=/vins_fusion/imu_propagate"'


fn_tmux_attach "$SESSION"
