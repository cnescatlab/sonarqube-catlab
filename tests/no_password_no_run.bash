#!/usr/bin/env bash

# User Story:
# As a SonarQube user, I want the container not to start when I forget to
# set the admin password so that the default admin password cannot be used.

. tests/functions.bash


test_password()
{
    # Start a container
    if [ -z "$1" ]
    then
        docker run -d --name tmp lequal/sonarqube 
    else
        docker run -d --name tmp -e SONARQUBE_ADMIN_PASSWORD="$1" lequal/sonarqube
    fi

    # Wait for it to crash (or start)
    sleep 3

    # Get its logs
    output=$(docker container logs tmp)

    # Remove the container
    docker container rm -f tmp

    if ! echo -e "$output" | grep -q "Failed to start CNES SonarQube.";
    then
        msg="the container did not exit when started without SONARQUBE_ADMIN_PASSWORD"
        if [ -n "$1" ]
        then
            msg="the container did not exit when started with SONARQUBE_ADMIN_PASSWORD=$1"
        fi
        log "$ERROR" "$msg"
        >&2 echo -e "Logs are:\n$output"
        exit 1
    fi
}

# Test both cases: no password, "admin"
test_password ""
test_password "admin"

log "$INFO" "the container cannot be started without SONARQUBE_ADMIN_PASSWORD."
exit 0
