#!/usr/bin/env bash

# This file is the entrypoint of the image
# It must be executed as an unprivileged user

# Fail on error
set -e

# Make sur the admin password will be changed
if [ -z "$SONARQUBE_ADMIN_PASSWORD" ] || [ "$SONARQUBE_ADMIN_PASSWORD" = "admin" ]
then
    echo >&2 "Error: The default admin password is 'admin', a more secure password must be used."
    echo >&2 "Please set variable throught `-e SONARQUBE_ADMIN_PASSWORD=<password>` parameter in your docker run"
    echo >&2 "Password must include 12 characters including 1 upper, 1 lower, 1 number and 1 special"
    echo >&2 "Unable to start CNES SonarQube."
    exit 1
fi

# Launch the configuration in its own process
./bin/configure.bash &

# Finally substitute the current process with the
# entrypoint of SonarQube to start the server
exec ./docker/entrypoint.sh
