#!/usr/bin/env bash

# User Story:
# As a user, I want the server to be UP so that I can use it.

. tests/functions.bash

sonar_status=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                 "$SONARQUBE_URL/api/system/status" \
                | jq -r '(.status)')

if [ "$sonar_status" != "UP" ]
then
    log "$ERROR" "SonarQube server is $sonar_status, it should be UP"
    >&2 echo "curl -su admin:$SONARQUBE_ADMIN_PASSWORD $SONARQUBE_URL/api/system/status"
    >&2 curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" "$SONARQUBE_URL/api/system/status"
    exit 1
fi

log "$INFO" "SonarQube is UP"
exit 0
