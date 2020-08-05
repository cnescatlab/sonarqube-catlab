#!/usr/bin/env bash

# Evil User Story:
# As a hacker, I want to use the default admin password (=admin)
# to log in as admin.

. tests/functions.bash

status=$(curl -i -su admin:admin \
            --data-urlencode "login=admin" \
            --data-urlencode "password=admin" \
            "$SONARQUBE_URL/api/authentication/login" \
        | sed -n -r -e 's/^HTTP\/.+ ([0-9]+)/\1/p')
# Remove the trailing new line
status=${status:0:3}

if [ "$status" = "401" ]
then
    log "$INFO" "Hacker unauthorized"
    # Success
    exit 0
elif [ "$status" = "200" ]
then
    log "$WARNING" "Hacker logged in" "${0##*/}"
else
    log "$ERROR" "unexpected HTTP status $status" "${0##*/}"
fi

# Print the output to STDERR
>&2 echo "curl -i -su admin:admin --data-urlencode login=admin --data-urlencode password=admin $SONARQUBE_URL/api/authentication/login"
>&2 curl -i -su admin:admin --data-urlencode "login=admin" --data-urlencode "password=admin" "$SONARQUBE_URL/api/authentication/login"

# Failure
exit 1
