#! /usr/bin/bash

source /opt/ros/noetic/setup.bash
# Making sure that we don't use any custmoied pkgs.


echo "nv" | sudo -S chmod 777 /dev/ttyTHS0;
roscore & sleep 10;
roslaunch mavros px4.launch fcu_url:="/dev/ttyTHS0:921600" & sleep 4;
rosrun mavros mavcmd long 511 31 5000 0 0 0 0 0 & sleep 1;   # ATTITUDE_QUATERNION
rosrun mavros mavcmd long 511 105 5000 0 0 0 0 0 & sleep 1;  # HIGHRES_IMU
rosrun mavros mavcmd long 511 106 20000 0 0 0 0 0 & sleep 1;  # HIGHRES_IMU
rosrun mavros mavcmd long 511 147 10000 0 0 0 0 0 & sleep 1;
rosrun mavros mavcmd long 511 147 5000 0 0 0 0 0 & sleep 1;  # BATTERY_STATUS



############## MOTION CAPTION ODOMETRY ##################################################
roslaunch vrpn_client_ros sample.launch server:=10.1.1.198 & sleep 2;
##TODO hovering.
roslaunch ekf_quat nokov.launch & sleep 2;




roslaunch px4ctrl run_ctrl_nnpolicy.launch & sleep 2;
echo "nv" | sudo jetson_clocks & sleep 2;
