cmake_minimum_required(VERSION 2.8.3)
project(ros12_bridge)


##################
## Dependencies ##
##################

## add in all packages here that are required to be converted an bridged between 1 and 2 
# think of this a meta depend list
set(PKG_DEPS
    #mycustompackage_msgs
)
find_package(catkin REQUIRED COMPONENTS ${PKG_DEPS})

######################
## ROS2 Build Steps ##
######################

option(CMAKE_FORCE_ROS12_REBUILD "Force Ros12 Bridge rebuild" OFF)

if ("$ENV{ROS2_WS_PATH}" STREQUAL "")
  message(FATAL_ERROR "env var ROS2_WS_PATH is undefined" )
endif()
if ("$ENV{ROS1_WS_PATH}" STREQUAL "")
  message(FATAL_ERROR "env var ROS1_WS_PATH is undefined" )
endif()
if (CMAKE_FORCE_ROS12_REBUILD) 
  set(cleanros2 "--clean-all")
  message(WARNING "Using the clean all option `${cleanros2}`.\nBe patient this might take ~10 minutes\nTo unset it `--cmake-args -DCMAKE_FORCE_ROS12_REBUILD=OFF`")
else()
  set(cleanros2 "--no-clean-bridge")
  message(STATUS "Will check for changes.\nTo force a rebuild use `--cmake-args -DCMAKE_FORCE_ROS12_REBUILD=ON`")
endif()
message(STATUS "Entering the ROS2 build context.")
add_custom_target( build_ros1_bridge_in_ros2_ws ALL
    COMMAND ./ros2_builder "${cleanros2}" --file=../pkg_build_config.yaml
    WORKING_DIRECTORY  ${CMAKE_CURRENT_SOURCE_DIR}/resource/
    COMMENT "building ros2 parts"
    SOURCES pkg_build_config.yaml 
)

##############

catkin_package(
  CATKIN_DEPENDS ${PKG_DEPS}
)

catkin_install_python(PROGRAMS scripts/ros12_bridge
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION})

install(DIRECTORY launch/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/launch)
install(DIRECTORY config/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config)