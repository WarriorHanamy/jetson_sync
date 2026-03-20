#include <ros/ros.h>
#include <geometry_msgs/PoseStamped.h>
#include <nav_msgs/Odometry.h>
#include <limits>
#include <mutex>

class MocapToMavrosOdom {
public:
  MocapToMavrosOdom() : has_data_(false) {
    ros::NodeHandle pnh("~");
    pnh.param("output_rate", output_rate_, 50.0);
    sub_ = pnh.subscribe("pose", 50, &MocapToMavrosOdom::cb, this);
    pub_ = pnh.advertise<nav_msgs::Odometry>("/mavros/odometry/out", 50);
    timer_ = pnh.createTimer(ros::Duration(1.0 / output_rate_), &MocapToMavrosOdom::timerCb, this);
  }

private:
  ros::Subscriber sub_;
  ros::Publisher pub_;
  ros::Timer timer_;
  double output_rate_;
  geometry_msgs::PoseStamped latest_pose_;
  bool has_data_;
  std::mutex mutex_;

  void cb(const geometry_msgs::PoseStamped::ConstPtr& msg) {
    std::lock_guard<std::mutex> lock(mutex_);
    latest_pose_ = *msg;
    has_data_ = true;
  }

  void timerCb(const ros::TimerEvent&) {
    geometry_msgs::PoseStamped msg;
    {
      std::lock_guard<std::mutex> lock(mutex_);
      if (!has_data_) return;
      msg = latest_pose_;
    }

    nav_msgs::Odometry out;
    out.header.stamp = msg.header.stamp;
    out.header.frame_id = "odom";
    out.child_frame_id = "base_link";

    double px = msg.pose.position.x;
    double py = msg.pose.position.y;
    double pz = msg.pose.position.z;

    if (std::abs(px) > 1000.0 || std::abs(py) > 1000.0 || std::abs(pz) > 1000.0) {
      px /= 1000.0;
      py /= 1000.0;
      pz /= 1000.0;
    }

    out.pose.pose.position.x = px;
    out.pose.pose.position.y = py;
    out.pose.pose.position.z = pz;

    double nan_val = std::numeric_limits<double>::quiet_NaN();
    out.twist.twist.linear.x = nan_val;
    out.twist.twist.linear.y = nan_val;
    out.twist.twist.linear.z = nan_val;
    out.twist.twist.angular.x = nan_val;
    out.twist.twist.angular.y = nan_val;
    out.twist.twist.angular.z = nan_val;

    out.pose.pose.orientation = msg.pose.orientation;

    pub_.publish(out);
  }
};

int main(int argc, char** argv) {
  ros::init(argc, argv, "mocap_to_mavros_odom");
  MocapToMavrosOdom node;
  ros::spin();
  return 0;
}
