cmake_minimum_required(VERSION 3.0.2)
project(simple_px4_odom)

find_package(catkin REQUIRED COMPONENTS
  roscpp
  nav_msgs
  cmake_modules
)

find_package(Eigen3 REQUIRED)

catkin_package()

include_directories(
  ${catkin_INCLUDE_DIRS}
  ${EIGEN3_INCLUDE_DIR}
)

add_executable(vio_to_mavros_odom src/vio_to_mavros_odom.cpp)
target_link_libraries(vio_to_mavros_odom ${catkin_LIBRARIES})

add_executable(mocap_to_mavros_odom src/mocap_to_mavros_odom.cpp)
target_link_libraries(mocap_to_mavros_odom ${catkin_LIBRARIES})
