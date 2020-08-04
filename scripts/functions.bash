#!/usr/bin/env bash

# This file contains all the useful functions
# used to configure the SonarQube instance.

# Constants
if [ -z "$SONARQUBE_URL" ]
then
    SONARQUBE_URL="http://localhost:9000"
fi

# log
#
# This function logs a line.
# Log levels are: INFO, WARNING, ERROR
# INFO are logged on STDOUT.
# WARNING and ERROR are logged on STDERR.
#
# Parameters:
#   1: level of log
#   2: message to log
#   3: (optional) cause
#
# Example:
#   $ log $ERROR "Something went wrong" "a_faulty_function"
export INFO="INFO"
export WARNING="WARNING"
export ERROR="ERROR"
log()
{
    msg="[$1] CNES SonarQube: $2"
    if [ -n "$3" ]
    then
        msg="$msg, caused by $3"
    fi
    if [ "$1" = "$INFO" ]
    then
        echo "$msg"
    else
        >&2 echo "$msg"
    fi
}

# wait_sonarqube_up
#
# This function waits for SonarQube to start and be
# in a UP status.
# If this function is run in background, call wait
# at some point.
#
# No parameter
#
# Environment variables required
#   * SONARQUBE_URL
#
# Example
#   $ wait_sonarqube_up
wait_sonarqube_up()
{
    sonar_status="DOWN"
    log $INFO "initiating connection with SonarQube."
    sleep 15
    while [ "${sonar_status}" != "UP" ]
    do
        sleep 5
        log $INFO "retrieving SonarQube's service status."
        sonar_status=$(curl -s -X GET "${SONARQUBE_URL}/api/system/status" | jq -r '.status')
        log $INFO "SonarQube is ${sonar_status}, expecting it to be UP."
    done
    log $INFO "SonarQube is ${sonar_status}."
}

# wait_lequalsonarqube_ready
#
# This function waits for SonarQube to be configured by
# the configure.bash script.
# If this function is run in background, call wait
# at some point.
#
# Parameters:
#   1: name of the container running lequal/sonarqube
#
# Environment variables required
#   * SONARQUBE_URL
#
# Example
#   $ wait_lequalsonarqube_ready lequalsonarqube
wait_lequalsonarqube_ready()
{
    container_name="$1"
    while ! docker container logs "$container_name" 2>&1 | grep -q '\[INFO\] CNES SonarQube: ready!';
    do
        >&2 echo "Waiting for SonarQube to be UP. (docker-compose)"
        sleep 5
    done
}
