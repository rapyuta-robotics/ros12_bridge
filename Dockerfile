FROM ros:jazzy AS jazzy-noetic
ENV ROS_DISTRO=noetic

WORKDIR /tmp/ws
RUN bash -e <<EOF
    echo 'Etc/UTC' > /etc/timezone
    apt-get update -qq
    apt-get install -q -y \
        tzdata \
        python3-rosinstall-generator \
        python3-vcstool \
        python3-rosdep \
        git \
        build-essential \
        ros-jazzy-rmw-zenoh-cpp
    rm -rf /etc/ros/rosdep/sources.list.d/20-default.list
    rosinstall_generator ros_core geometry_msgs actionlib_msgs --rosdistro noetic --deps --tar > ros.rosinstall
    mkdir src
    vcs import --input ros.rosinstall ./src
    rosdep init
    rosdep update --rosdistro noetic --include-eol-distros
    rosdep install --from-paths ./src --ignore-src --rosdistro noetic -y
EOF

COPY patches/rosconsole.patch /tmp/ws/src/rosconsole
RUN bash -e <<EOF
    cd /tmp/ws/src/rosconsole
    git apply rosconsole.patch
    cd /tmp/ws
    ./src/catkin/bin/catkin_make_isolated \
        --install \
        --install-space /opt/ros/noetic \
        --cmake-args -DCMAKE_BUILD_TYPE=Release
    apt-get purge -y python3-rosinstall-generator python3-vcstool git
    apt-get autoremove -y
    rm -r /tmp/ws /root/.ros /var/lib/apt/lists/*
EOF
WORKDIR /
COPY ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]


FROM jazzy-noetic AS ros1-msgs
WORKDIR /tmp
ADD git@github.com:rapyuta-robotics/rr_localization_interfaces.git src/rr_localization_interfaces/
ADD git@github.com:rapyuta-robotics/rr_base.git src/rr_base/
ADD git@github.com:rapyuta-robotics/rr_amr_common.git src/rr_amr_common/ 
RUN bash -e <<EOF
    mkdir -p /opt/rapyuta/noetic
    source /opt/ros/noetic/setup.bash
    catkin_make_isolated \
        --force-cmake \
        --install \
        --install-space /opt/rapyuta/noetic \
        --only-pkg-with-deps rr_localization_interfaces rr_lbc_msgs \
        --cmake-args -DCMAKE_BUILD_TYPE=Release
EOF

FROM jazzy-noetic AS ros2-msgs
WORKDIR /tmp
ADD git@github.com:rapyuta-robotics/rr_localization_interfaces.git#ros2 src/rr_localization_interfaces/
ADD git@github.com:rapyuta-robotics/rr_base.git#ros2 src/rr_base/
ADD git@github.com:rapyuta-robotics/rr_amr_common.git#jazzy src/rr_amr_common/ 
RUN bash -e <<EOF
    mkdir -p /opt/rapyuta/jazzy
    source /opt/ros/jazzy/setup.bash
    colcon build \
        --merge-install \
        --install-base /opt/rapyuta/jazzy \
        --packages-up-to rr_localization_interfaces rr_lbc_msgs \
        --cmake-force-configure \
        --cmake-args -DCMAKE_BUILD_TYPE=Release
EOF

FROM jazzy-noetic AS build-bridge
COPY --from=ros1-msgs /opt/rapyuta/noetic /opt/rapyuta/noetic
COPY --from=ros2-msgs /opt/rapyuta/jazzy /opt/rapyuta/jazzy
WORKDIR /tmp
ADD https://github.com/ros2/ros1_bridge.git src/
RUN bash -e <<EOF
    source /opt/rapyuta/noetic/setup.bash
    source /opt/rapyuta/jazzy/setup.bash
    apt-get update -qq
    rosdep update --rosdistro jazzy
    echo "set -e" > install_deps.sh
    chmod +x install_deps.sh
    rosdep install --rosdistro jazzy --ignore-src --from-paths src/ --simulate \
        | sed 's/install/install -y/' \
        | tee -a install_deps.sh
    ./install_deps.sh
    colcon build --merge-install --packages-select ros1_bridge --cmake-force-configure --install-base /opt/ros/jazzy
EOF

FROM jazzy-noetic
COPY --from=build-bridge /opt/ros/jazzy /opt/ros/jazzy
COPY --from=ros1-msgs /opt/rapyuta/noetic /opt/rapyuta/noetic
COPY --from=ros2-msgs /opt/rapyuta/jazzy /opt/rapyuta/jazzy
COPY --from=build-bridge /tmp/install_deps.sh /tmp
ENV ROS_DISTRO= 
RUN bash -e <<EOF
    apt-get update -qq
    ./tmp/install_deps.sh
    rm -r /var/lib/apt/lists/*
EOF
WORKDIR /opt/rapyuta