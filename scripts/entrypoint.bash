#!/usr/bin/env bash

# This file is the entrypoint of the image
# It must be executed as an unprivileged user

# Fail on error
set -e

# Make sur the admin password will be changed
if [ -z "$SONARQUBE_ADMIN_PASSWORD" ] || [ "$SONARQUBE_ADMIN_PASSWORD" = "admin" ]
then
    echo "The default admin password is 'admin', a more secure password must be used."
    echo "Failed to start LEQUAL SonarQube."
    exit 1
fi

# Launch the configuration
./bin/configure.bash &

# Finally call the initial entrypoint of SonarQube to start the server
exec ./bin/run.sh
