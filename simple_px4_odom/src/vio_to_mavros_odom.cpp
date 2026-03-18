#include <ros/ros.h>
#include <nav_msgs/Odometry.h>

class VioToMavrosOdom {
public:
  VioToMavrosOdom() {
    ros::NodeHandle nh;
    ros::NodeHandle pnh("~");
    sub_ = pnh.subscribe("odom", 50, &VioToMavrosOdom::cb, this);
    pub_ = nh.advertise<nav_msgs::Odometry>("/mavros/odometry/out", 50);
  }

private:
  ros::Subscriber sub_;
  ros::Publisher pub_;

  void cb(const nav_msgs::Odometry::ConstPtr& msg) {
    nav_msgs::Odometry out = *msg;

    out.header.stamp = ros::Time::now();
    out.header.frame_id = "odom_frd";
    out.child_frame_id = "base_link_frd";

    out.pose.pose.position.x =  msg->pose.pose.position.x;
    out.pose.pose.position.y = -msg->pose.pose.position.y;
    out.pose.pose.position.z = -msg->pose.pose.position.z;

    out.twist.twist.linear.x =  msg->twist.twist.linear.x;
    out.twist.twist.linear.y = -msg->twist.twist.linear.y;
    out.twist.twist.linear.z = -msg->twist.twist.linear.z;

    out.twist.twist.angular.x =  msg->twist.twist.angular.x;
    out.twist.twist.angular.y = -msg->twist.twist.angular.y;
    out.twist.twist.angular.z = -msg->twist.twist.angular.z;

    out.pose.pose.orientation.w =  msg->pose.pose.orientation.w;
    out.pose.pose.orientation.x =  msg->pose.pose.orientation.x;
    out.pose.pose.orientation.y = -msg->pose.pose.orientation.y;
    out.pose.pose.orientation.z = -msg->pose.pose.orientation.z;

    pub_.publish(out);
  }
};

int main(int argc, char** argv) {
  ros::init(argc, argv, "vio_to_mavros_odom");
  VioToMavrosOdom node;
  ros::spin();
  return 0;
}
