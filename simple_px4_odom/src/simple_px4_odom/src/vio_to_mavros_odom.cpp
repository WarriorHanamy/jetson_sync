#include <ros/ros.h>
#include <nav_msgs/Odometry.h>
#include <Eigen/Geometry>

class VioToMavrosOdom {
public:
  VioToMavrosOdom() : last_pub_time_(0) {
    ros::NodeHandle pnh("~");
    pnh.param("output_rate", output_rate_, 50.0);
    min_interval_ = 1.0 / output_rate_;
    sub_ = pnh.subscribe("odom", 50, &VioToMavrosOdom::cb, this);
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

  void cb(const nav_msgs::Odometry::ConstPtr& msg) {
    ros::Time now = ros::Time::now();
    if ((now - last_pub_time_).toSec() < min_interval_) return;
    last_pub_time_ = now;

    nav_msgs::Odometry out;
    out.header.stamp = ros::Time::now();
    out.header.frame_id = "odom";
    out.child_frame_id = "base_link";

    Eigen::Vector3d p_enu(msg->pose.pose.position.x,
                          msg->pose.pose.position.y,
                          msg->pose.pose.position.z);
    Eigen::Vector3d p_ned = q_enu_ned * p_enu;

    out.pose.pose.position.x = p_ned.x();
    out.pose.pose.position.y = p_ned.y();
    out.pose.pose.position.z = p_ned.z();

    Eigen::Vector3d v_enu(msg->twist.twist.linear.x,
                          msg->twist.twist.linear.y,
                          msg->twist.twist.linear.z);
    Eigen::Vector3d v_ned = q_enu_ned * v_enu;

    out.twist.twist.linear.x = v_ned.x();
    out.twist.twist.linear.y = v_ned.y();
    out.twist.twist.linear.z = v_ned.z();

    Eigen::Vector3d w_flu(msg->twist.twist.angular.x,
                          msg->twist.twist.angular.y,
                          msg->twist.twist.angular.z);
    Eigen::Vector3d w_frd = q_flu_frd * w_flu;

    out.twist.twist.angular.x = w_frd.x();
    out.twist.twist.angular.y = w_frd.y();
    out.twist.twist.angular.z = w_frd.z();

    Eigen::Quaterniond q_enu_flu(msg->pose.pose.orientation.w,
                                  msg->pose.pose.orientation.x,
                                  msg->pose.pose.orientation.y,
                                  msg->pose.pose.orientation.z);
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

const Eigen::Quaterniond VioToMavrosOdom::q_enu_ned(0.0, M_SQRT1_2, M_SQRT1_2, 0.0);
const Eigen::Quaterniond VioToMavrosOdom::q_flu_frd(0.0, 1.0, 0.0, 0.0);

int main(int argc, char** argv) {
  ros::init(argc, argv, "vio_to_mavros_odom");
  VioToMavrosOdom node;
  ros::spin();
  return 0;
}
