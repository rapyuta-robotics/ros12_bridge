# Ros12 Bridge

`ros12_bridge` is a shim package to help build run and manipulate the [`ros1_bridge`](https://github.com/ros2/ros1_bridge) 
bridge maintained by the OSRF to bridge topics and services between ROS2<=> ROS1

## Features

 * Shim package native ROS1 package
 * Native ros1 tooling
   * Builds with catkin - tested with kinetic/melodic - bouncy/crystal/dashing
   * Depend on other ros1 packages
   * Works with roslaunch 
 * Automates ROS2 workspace
   * Automatically generate packages, messages and services and mapping
   *  Detect changes rebuild if required -> packages and bridge
 * Supports using regular expression to whitelist topics/services (you must use [this fork](https://github.com/rapyuta-robotics/ros1_bridge) until upstream merge is accepted )


## Usage

The utiltities are modelled as a ros 1 package `ros12_bridge`

Set the env paths to your ROS1 and ROS2 workspaces

 * ROS1_WS_PATH
 * ROS2_WS_PATH

eg:
`export ROS1_WS_PATH=~/ws;export ROS2_WS_PATH=~/ros2_ws`

To build the bridge simply `catkin build ros12_bridge`

This autodetects changes in most files to be sure force a rebuild using cmake flag FORCE_ROS12_REBUILD=ON

eg: `catkin build ros12_bridge --cmake-args -DCMAKE_FORCE_ROS12_REBUILD=ON`

Remember to *unset* this flag else it'll add ~8 min to your build time each time.

eg: `catkin build ros12_bridge --cmake-args -DCMAKE_FORCE_ROS12_REBUILD=OFF`

To run the bridge `roslaunch ros12_bridge example.launch`

### Build and track dependencies 
The CMakeLists.txt and package.xml can be modified to ensure your dependency trees 
are satisfied by catkin before templating and switching into colcon to build ROS2

Modify the `pkg_build_config.yaml` to add depends you want converted


##### Note for resource limitation (can result in sneaky internal compiler errors):

Set the MAKEFLAGS to be passed into ROS2 :

eg: `export ROS2_MAKEFLAGS=-j2` (j2 is default, ymmv)

## Package Convertor

Generate ROS2 _ports_ for your ros1 packages:

This utility essentially converts and maps your package message and service types
 to ros2 packages. It also performs some convention conversions between ROS1 and ROS2.
 
 Next the tool builds your ros2 packages and **then** proceeds  builds the `ros1_bridge` in the ROS2 workspace 
 so that it works with all your message types.
 
 The final output of the utility  is a list of compatible ROS1<=> ROS2 types that the bridge is equiped to bridge
 

 * Make sure you have sourced all your ROS1 related workspaces and can see your messages using rosmsg tools.
 * DO NOT source your ros2 workspace
 
 Note on converting dependencies: 
 * In another terminal (with ros2 sourced) run `ros2 msg list` to see what you need, most common types exist in ROS2
 * Make sure you add all your required packages and interdepends in the yaml file. THIS IS YOUR RESPONSIBLITY

Set the env paths to your ROS1 and ROS2 workspaces
 * ROS1_WS_PATH
 * ROS2_WS_PATH

eg:
`export ROS1_WS_PATH=~/ws;export ROS2_WS_PATH=~/ros2_ws`

##### Note for resource limitation (can result in sneaky internal compiler errors):

Set the MAKEFLAGS to be passed into ROS2 :

eg: `export ROS2_MAKEFLAGS=-j2` (j2 is default, ymmv)

#### Using a explicit yaml file

`./resource/ros2_builder -vv --clean-all --file=convert.yaml`

**Sample file at:**  pkg_build_config.yaml.sample

#### Implicit detection
Alternately we can pick up packages from all sourced ros1 workspaces 
if they contain the '_.genros2_' file

`./resource/ros2_builder`

##### Misc Opts
 * Increase levels of verbosity using :-vv
 * Use --help to see other options.

## Bridge Runner

This utility helps you run the `ros1_bridge` to bridge specific topics to ROS2 bidirectionally 
 
 Note: At the time of writing this only works for topics not services. Please read the upstream docs for services
 
 * Source only the root ros1 workspace eg: `/opt/ros/kinetic/setup.bash`
 This should set the ROS_MASTER_URI , alternatively set it : `export ROS_MASTER_URI=http://localhost:11311`

Set the env paths to your ROS2 workspaces
 * ROS2_WS_PATH (optional: can be passed as a command line arg too) 

eg:
`export  ROS2_WS_PATH=~/ros2_ws`

Then launch the bridge
`./scripts/ros12_bridge --config=topic.yaml --ros2-ws-path=~/ros2_ws`

##### Misc Opts
 * **Sample file at:** config/topic.yaml.sample
 * Use --help to see other options.

## Authors
 * Dhananjay Sathe <dhananjay.sathe@rapyuta-robotics.com>