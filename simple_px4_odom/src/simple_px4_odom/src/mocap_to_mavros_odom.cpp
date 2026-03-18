#include <ros/ros.h>
#include <geometry_msgs/PoseStamped.h>
#include <nav_msgs/Odometry.h>
#include <Eigen/Geometry>
#include <limits>

class MocapToMavrosOdom {
public:
  MocapToMavrosOdom() : last_pub_time_(0) {
    ros::NodeHandle pnh("~");
    pnh.param("output_rate", output_rate_, 50.0);
    min_interval_ = 1.0 / output_rate_;
    sub_ = pnh.subscribe("pose", 50, &MocapToMavrosOdom::cb, this);
    pub_ = pnh.advertise<nav_msgs::Odometry>("/mavros/odometry/out", 50);
  }

private:
  ros::Subscriber sub_;
  ros::Publisher pub_;
  double output_rate_;
  double min_interval_;
  ros::Time last_pub_time_;

  static const Eigen::Quaterniond q_enu_ned;
  static const Eigen::Quaterniond q_flu_frd;

  void cb(const geometry_msgs::PoseStamped::ConstPtr& msg) {
    ros::Time now = ros::Time::now();
    if ((now - last_pub_time_).toSec() < min_interval_) return;
    last_pub_time_ = now;

    nav_msgs::Odometry out;
    out.header.stamp = ros::Time::now();
    out.header.frame_id = "odom";
    out.child_frame_id = "base_link";

    Eigen::Vector3d p_enu(msg->pose.position.x,
                          msg->pose.position.y,
                          msg->pose.position.z);
    Eigen::Vector3d p_ned = q_enu_ned * p_enu;

    out.pose.pose.position.x = p_ned.x();
    out.pose.pose.position.y = p_ned.y();
    out.pose.pose.position.z = p_ned.z();

    double nan_val = std::numeric_limits<double>::quiet_NaN();
    out.twist.twist.linear.x = nan_val;
    out.twist.twist.linear.y = nan_val;
    out.twist.twist.linear.z = nan_val;
    out.twist.twist.angular.x = nan_val;
    out.twist.twist.angular.y = nan_val;
    out.twist.twist.angular.z = nan_val;

    Eigen::Quaterniond q_enu_flu(msg->pose.orientation.w,
                                  msg->pose.orientation.x,
                                  msg->pose.orientation.y,
                                  msg->pose.orientation.z);
    q_enu_flu.normalize();
    Eigen::Quaterniond q_ned_frd = q_enu_ned * q_enu_flu * q_flu_frd;
    q_ned_frd.normalize();

    out.pose.pose.orientation.w = q_ned_frd.w();
    out.pose.pose.orientation.x = q_ned_frd.x();
    out.pose.pose.orientation.y = q_ned_frd.y();
    out.pose.pose.orientation.z = q_ned_frd.z();

    pub_.publish(out);
  }
};

const Eigen::Quaterniond MocapToMavrosOdom::q_enu_ned(0.0, M_SQRT1_2, M_SQRT1_2, 0.0);
const Eigen::Quaterniond MocapToMavrosOdom::q_flu_frd(0.0, 1.0, 0.0, 0.0);

int main(int argc, char** argv) {
  ros::init(argc, argv, "mocap_to_mavros_odom");
  MocapToMavrosOdom node;
  ros::spin();
  return 0;
}
