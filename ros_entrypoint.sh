#!/bin/bash
set -e

if [[ -n "$ROS_DISTRO" ]]; then
    source "/opt/rapyuta/$ROS_DISTRO/setup.bash" --
fi
exec "$@"
