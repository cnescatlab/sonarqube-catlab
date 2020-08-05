#!/usr/bin/env bash

# This file contains useful functions for tests
# of the sonar-scanner.

# Default values of environment variables
if [ -z "$SONARQUBE_CONTAINER_NAME" ]
then
    export SONARQUBE_CONTAINER_NAME=lequalsonarqube
fi

if [ -z "$SONARQUBE_ADMIN_PASSWORD" ]
then
    export SONARQUBE_ADMIN_PASSWORD="adminpassword"
fi

if [ -z "$SONARQUBE_URL" ]
then
    export SONARQUBE_URL="http://localhost:9000"
fi

# ============================================================================ #

# log
#
# This function logs a line.
# Log levels are: INFO, ERROR
# INFO are logged on STDOUT.
# ERROR are logged on STDERR.
#
# Parameters:
#   1: level of log
#   2: message to log
#
# Example:
#   $ log "$ERROR" "Something went wrong"
export INFO="INFO"
export ERROR="ERROR"
log()
{
    msg="[$1] Test CNES SonarQube: $2"
    if [ "$1" = "$INFO" ]
    then
        echo "$msg"
    else
        >&2 echo "$msg" ", raised by ${0##*/}"
    fi
}

# wait_cnes_sonarqube_ready
#
# This function waits for SonarQube to be configured by
# the configure.bash script.
# If this function is run in background, call wait
# at some point.
#
# Parameters:
#   1: name of the container running lequal/sonarqube
#
# Example:
#   $ wait_cnes_sonarqube_ready lequalsonarqube
wait_cnes_sonarqube_ready()
{
    container_name="$1"
    while ! docker container logs "$container_name" 2>&1 | grep -q '\[INFO\] CNES SonarQube: ready!';
    do
        log "$INFO" "Waiting for CNES SonarQube to be ready."
        sleep 5
    done
}
