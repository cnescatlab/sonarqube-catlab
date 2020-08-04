#!/usr/bin/env bash

# This script is a test launcher.
# It runs a container of the image and launch all the scripts in
# the tests/ folder.
# It does not build the image.
#
# It must be launched from the root folder of the project like this:
#   $ ./tests/run_tests.bash
#
# Parameters:
#   --no-run: if this option is specified, the script will not run
#             the container. It will only launch the tests.
#             In this case, make sur to set necessary environment
#             variables.
#
# Environment:
#   SONARQUBE_CONTAINER_NAME: the name to give to the container running
#                             the image.
#   SONARQUBE_ADMIN_PASSWORD: the password of the admin account.
#   SONARQUBE_URL: URL of lequal/sonarqube container if already running
#                  without trailing / from the host.
#                  e.g. http://localhost:9000
#
# Examples:
#   $ ./tests/run_tests.bash
#   $ SONARQUBE_CONTAINER_NAME=lequalsonarqube_sonarqube_1 SONARQUBE_ADMIN_PASSWORD=pass ./tests/run_tests.bash --no-run

. scripts/functions.bash

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

# Unless required not to, a container is run
if [ "$1" != "--no-run" ]
then
    # Run a container
    docker run --name "$SONARQUBE_CONTAINER_NAME" \
            -d --rm \
            -p 9000:9000 \
            -e SONARQUBE_ADMIN_PASSWORD="$SONARQUBE_ADMIN_PASSWORD" \
            lequal/sonarqube:latest

    # When the script ends stop the container
    atexit()
    {
        docker container stop "$SONARQUBE_CONTAINER_NAME" > /dev/null
    }
    trap atexit EXIT
fi

# Wait the configuration of the image before running the tests
wait_cnes_sonarqube_ready "$SONARQUBE_CONTAINER_NAME"

# Launch tests
failed="0"
nb_test="0"
for script in tests/*
do
    if [ -f "$script" ] && [ -x "$script" ] && [ "$script" != "tests/run_tests.bash" ] && [ "$script" != "tests/README.md" ]
    then
        # Launch each test (only print warnings and errors)
        echo -n "Launching test $script..."
        if ! ./"$script" > /dev/null;
        then
            echo "failed"
            ((failed++))
        else
            echo "success"
        fi
        ((nb_test++))
    fi
done
echo "$failed tests failed out of $nb_test"

exit $failed
