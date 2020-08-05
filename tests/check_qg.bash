#!/usr/bin/env bash

# User Story:
# As a SonarQube user, I want the SonarQube server to have the
# CNES Quality Gate configured and set as default so that I can
# use it.

. tests/functions.bash

quality_gates=$(curl -s "$SONARQUBE_URL/api/qualitygates/list")

if [ "$(echo "$quality_gates" | jq '.qualitygates | map(select(.name == "CNES"))')" = "[]" ]
then
    log "$ERROR" "no Quality Gate named CNES on the server" "${0##*/}"
    >&2 echo "curl -s $SONARQUBE_URL/api/qualitygates/list"
    >&2 echo "$quality_gates"
    exit 1
fi

if [ "$(echo "$quality_gates" | jq '.qualitygates | map(select(.name == "CNES"))[].isDefault')" != "true" ]
then
    log "$ERROR" "the CNES Quality Gate is not the default gate" "${0##*/}"
    >&2 echo "curl -s $SONARQUBE_URL/api/qualitygates/list"
    >&2 echo "$quality_gates"
    exit 1
fi

log "$INFO" "CNES Quality Gate is the default."
exit 0
