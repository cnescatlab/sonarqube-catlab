#!/usr/bin/env bash

# This script configures the SonarQube instance.
# It adds
#   * CNES Quality profiles
#   * CNES Quality Gates

# Fail on error
set -e

# Include useful functions
. ./bin/functions.bash

# create_quality_gate
#
# This function adds the CNES quality gate to a SonarQube server.
#
# Parameters:
#   1: Quality Gate file to import
#
# Example:
#   $ create_quality_gate
create_quality_gate()
{
    FILE=$1
    NAME=$(jq -r '.name' "$FILE")
    log "$INFO" "creating '$NAME' quality gate."
    res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                --data-urlencode "name=$NAME" \
                "${SONARQUBE_URL}/api/qualitygates/create")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
    then
        log "$INFO" "successfully created '$NAME' quality gate... now configuring it."
    else
        log "$WARNING" "impossible to create quality gate" "$(echo "${res}" | jq '.errors[].msg')"
    fi

    # Retrieve quality gates ID
    log "$INFO" "retrieving '$NAME' quality gate ID."
    res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                -G \
                --data-urlencode "name=$NAME" \
                "${SONARQUBE_URL}/api/qualitygates/show")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
    then
        GATEID="$(echo "${res}" |  jq -r '.id')"
        log "$INFO" "successfully retrieved quality gate ID (ID=$GATEID)."
    else
        log "$ERROR" "impossible to reach quality gate ID" "$(echo "${res}" | jq '.errors[].msg')"
    fi

    # Setting it as default quality gate
    if [ "$NAME" = "CNES" ]
    then
        log "$INFO" "setting CNES quality gate as default gate."
        res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                    --data-urlencode "id=${GATEID}" \
                    "${SONARQUBE_URL}/api/qualitygates/set_as_default")
        if [ -z "$res" ]
        then
            log "$INFO" "successfully set CNES quality gate as default gate."
        else
            log "$WARNING" "impossible to set CNES quality gate as default gate" "$(echo "${res}" | jq '.errors[].msg')"
        fi
    fi

    # Adding all conditions of the JSON file
    log "$INFO" "adding all conditions of $FILE to the gate."
    len=$(jq '(.conditions | length)' "$FILE")
    cnes_quality_gate=$(jq '(.conditions)' "$FILE")
    actual_quality_gate=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                -G \
                --data-urlencode "name=$NAME" \
                "${SONARQUBE_URL}/api/qualitygates/show")
    conditions=$(echo "$actual_quality_gate" | jq -r '.conditions[]')
    for i in $(seq 0 $((len - 1)))
    do
        metric=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].metric)')
        op=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].op)')
        error=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].error)')
        add_condition_to_quality_gate "$GATEID" "$conditions" "$metric" "$op" "$error"
    done
}

# add_condition_to_quality_gate
#
# This function adds a condition to an existing Quality Gate
# on a SonarQube server.
#
# Parameters:
#   1: gate_id
#   2: conditions
#   3: metric_key
#   4: metric_operator (EQ, NE, LT or GT)
#   5: metric's error threshold ("none" not to set it)
#
# Example:
#   $ add_condition_to_quality_gate "blocker_violations" "GT" "$GATEID" 0
add_condition_to_quality_gate()
{
    gate_id=$1
    conditions=$2
    metric_key=$3
    metric_operator=$4
    metric_errors=$5

    # Check if the metric is already configured
    existing_condition=$(echo "${conditions}" | jq -r "select(.metric == \"${metric_key}\")")

    # If the metric is already configured, update it
    if [ -n "$existing_condition" ]; then
        log "$INFO" "The metric '${metric}' is already configured. Updating it."
        condition_id=$(echo "${existing_condition}" | jq -r ".id")
        update_condition "$condition_id" "$metric_key" "$metric_operator" "$metric_errors"
    else
        # Add the new condition
        log "$INFO" "adding CNES quality gate condition: ${metric_key} ${metric_operator} ${metric_errors}."

        threshold=()
        if [ "${metric_errors}" != "none" ]
        then
            threshold=("--data-urlencode" "error=${metric_errors}")
        fi

        res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                    --data-urlencode "gateId=${gate_id}" \
                    --data-urlencode "metric=${metric_key}" \
                    --data-urlencode "op=${metric_operator}" \
                    "${threshold[@]}" \
                    "${SONARQUBE_URL}/api/qualitygates/create_condition")
        if [ "$(echo "${res}" | jq '(.errors | length)')" != "0" ]; then
            log "$WARNING" "impossible to add ${metric_key} condition" "$(echo "${res}" | jq '.errors[].msg')"  
        fi
    fi
}

# update_condition
#
# Updates a condition in an existing Quality Gate
# on a SonarQube server.
#
# Parameters:
#   1: condition_id
#   2: metric_key
#   3: metric_operator (EQ, NE, LT or GT)
#   4: metric's error threshold ("none" not to set it)
#
# Example:
#   $ add_condition_to_quality_gate "blocker_violations" "GT" "$GATEID" 0
update_condition()
{
    condition_id=$1
    metric_key=$2
    metric_operator=$3
    metric_errors=$4

    threshold=()
    if [ "${metric_errors}" != "none" ]
    then
        threshold=("--data-urlencode" "error=${metric_errors}")
    fi

    res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                --data-urlencode "id=${condition_id}" \
                --data-urlencode "metric=${metric_key}" \
                --data-urlencode "op=${metric_operator}" \
                "${threshold[@]}" \
                "${SONARQUBE_URL}/api/qualitygates/update_condition")
    if [ "$(echo "${res}" | jq '(.errors | length)')" != "0" ]; then
        log "$WARNING" "Impossible to update ${metric_key} condition" "$(echo "${res}" | jq '.errors[].msg')"
    fi
}

# add_quality_profile
#
# This function restores a Quality Profile to a SonarQube server
# from a file generated by a call to api/profiles/backup.
#
# Parameters:
#   1: Quality Profile file to import
#
# Example:
#   add_quality_profile conf/python/profiles/py-cnes_python_a-69347-quality-profile.xml
add_quality_profile()
{
    file=$1

    log "$INFO" "adding quality profile of file ${file}."
    res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                        --form backup=@"${file}" \
                        "${SONARQUBE_URL}/api/qualityprofiles/restore")
    if [ "$(echo "${res}" | jq '(.errors | length)')" != "0" ]; then
        log "$WARNING" "impossible to create ${file} quality profile" "$(echo "${res}" | jq '.errors[].msg')"
    fi
}

# create_quality_profiles
#
# This function imports quality profiles from conf/quality_profiles to SonarQube server.
create_quality_profiles()
{
    for file in $(find conf/quality_profiles -mindepth 2 -maxdepth 2 -type f)
    do
        add_quality_profile "${file}"
    done
    log "$INFO" "added all quality profiles."
}

# End of functions definition
# ============================================================================ #
# Start script

# Wait for SonarQube to be up
wait_sonarqube_up

# Make sure the database has not already been populated
status=$(curl -i -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
            "${SONARQUBE_URL}/api/qualitygates/list" \
    | sed -n -r -e 's/^HTTP\/.+ ([0-9]+)/\1/p')
status=${status:0:3} # remove \n
nb_qg=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
            "${SONARQUBE_URL}/api/qualitygates/list" \
    | jq '.qualitygates | map(select(.name == "CNES")) | length')
if [ "$status" -eq 200 ] && [ "$nb_qg" -eq 1 ]
then
    # admin password has already been changed and the CNES QG has already been added
    log "$INFO" "The database has already been filled with CNES configuration. Not adding anything."
else
    # Change admin password
    curl -su "admin:admin" \
        --data-urlencode "login=admin" \
        --data-urlencode "password=$SONARQUBE_ADMIN_PASSWORD" \
        --data-urlencode "previousPassword=admin" \
        "$SONARQUBE_URL/api/users/change_password"
    log "$INFO" "admin password changed."

    create_quality_profiles

    # Add QG
    for qg_file in conf/quality_gates/*
    do
        create_quality_gate "$qg_file"
    done
fi

# Tell the user, we are ready
log "$INFO" "ready!"

exit 0
