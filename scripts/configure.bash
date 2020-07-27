#!/usr/bin/env bash

# This script configures the SonarQube instance.
# It adds
#   * CNES rules
#   * CNES Quality profiles
#   * CNES Quality Gates

# Fail on error
set -e

# Include useful functions
. ./bin/functions.bash

# Define functions to add rules, QG, QP

#TODO

# End of function definition
# ============================================================================ #
# Start script

# Wait for SonarQube to be up
wait_sonarqube_up

# Change admin password
curl -su "admin:admin" \
    --data-urlencode "login=admin" \
    --data-urlencode "password=$SONARQUBE_ADMIN_PASSWORD" \
    --data-urlencode "previousPassword=admin" \
    $SONARQUBE_URL/api/users/change_password
log $INFO "admin password changed."

# Add GP
#TODO

# Add QG
#TODO

# Tell the user, we are ready
log $INFO "ready!"
