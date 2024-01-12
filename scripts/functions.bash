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
# Example:
#   $ wait_sonarqube_up
wait_sonarqube_up()
{
    sonar_status="DOWN"
    http_code=0
    log $INFO "initiating connection with SonarQube."
    sleep 15
    while [ "$http_code" -ne 200 ]
    do
        sleep 5
        http_code=$(curl -i -su "admin:$SONARQUBE_ADMIN_PASSWORD" "${SONARQUBE_URL}" \
        | sed -n -r -e 's/^HTTP\/.+ ([0-9]+)/\1/p')
        http_code=${http_code:0:3} # remove \n
        log $INFO "SonarQube HTTP code is ${http_code}, expecting it to be 200."
    done
    log $INFO "SonarQube HTTP code is ${http_code}"
    while [ "${sonar_status}" != "UP" ]
    do
        sleep 5
        sonar_status=$(curl -s -X GET "${SONARQUBE_URL}/api/system/status" | jq -r '.status')
        log $INFO "SonarQube is ${sonar_status}, expecting it to be UP."
    done
    log $INFO "SonarQube is ${sonar_status}."
}
