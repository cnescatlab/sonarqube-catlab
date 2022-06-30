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

# ============================================================================ #
# Define functions to add rules, QG, QP

# add_condition_to_quality_gate
#
# This function adds a condition to an existing Quality Gate
# on a SonarQube server.
#
# Parameters:
#   1: gate_id
#   2: metric_key
#   3: metric_operator (EQ, NE, LT or GT)
#   4: metric's error threshold ("none" not to set it)
#
# Example:
#   $ add_condition_to_quality_gate "blocker_violations" "GT" "$GATEID" 0
add_condition_to_quality_gate()
{
    gate_id=$1
    metric_key=$2
    metric_operator=$3
    metric_errors=$4

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
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
    then
        log "$INFO" "metric ${metric_key} condition successfully added."
    else
        log "$WARNING" "impossible to add ${metric_key} condition" "$(echo "${res}" | jq '.errors[].msg')"
    fi
}

# create_quality_gate
#
# This function adds the CNES quality gate to a SonarQube server.
#
# No parameters
#
# Example:
#   $ create_quality_gate
create_quality_gate()
{
    log "$INFO" "creating CNES quality gate."
    res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                --data-urlencode "name=CNES" \
                "${SONARQUBE_URL}/api/qualitygates/create")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
    then
        log "$INFO" "successfully created CNES quality gate... now configuring it."
    else
        log "$WARNING" "impossible to create quality gate" "$(echo "${res}" | jq '.errors[].msg')"
    fi

    # Retrieve CNES quality gates ID
    log "$INFO" "retrieving CNES quality gate ID."
    res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                --data-urlencode "name=CNES" \
                "${SONARQUBE_URL}/api/qualitygates/show")
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
    then
        GATEID="$(echo "${res}" |  jq -r '.id')"
        log "$INFO" "successfully retrieved CNES quality gate ID (ID=$GATEID)."
    else
        log "$ERROR" "impossible to reach CNES quality gate ID" "$(echo "${res}" | jq '.errors[].msg')"
    fi

    # Setting it as default quality gate
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

    # Adding all conditions of the JSON file
    log "$INFO" "adding all conditions of cnes-quality-gate.json to the gate."
    len=$(jq '(.conditions | length)' conf/cnes-quality-gate.json)
    cnes_quality_gate=$(jq '(.conditions)' conf/cnes-quality-gate.json)
    for i in $(seq 0 $((len - 1)))
    do
        metric=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].metric)')
        op=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].op)')
        error=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].error)')
        add_condition_to_quality_gate "$GATEID" "$metric" "$op" "$error"
    done
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
    if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
    then
        log "$INFO" "quality profile ${file} successfully created."
    else
        log "$WARNING" "impossible to create ${file} quality profile" "$(echo "${res}" | jq '.errors[].msg')"
    fi
}

# add_rules
#
# This function adds all rules contained in a JSON file to SonarQube.
#
# Parameters :
#   1: rule file in JSON format corresponding the the following format (Sonarqube 6.7.1 API /api/rules answer)
#
# Example:
#   $ add_rules conf/custom-java-rules-template.json
add_rules()
{
    file=$1

    log "$INFO" "processing rule file ${file} for addition to SonarQube."
    total=$(jq '.total' "${file}")
    for i in $(seq 0 $((total-1)))
    do
        log "$INFO" "adding custom rule $(jq -r '.rules['"${i}"'].key' "${file}")"
	    # for rule information registered using the rule creation API (/api/rules/create)
        # rule information
        custom_key=$(jq -r '.rules['"${i}"'].key' "${file}")
        markdown_description=$(jq '.rules['"${i}"'].mdDesc' "${file}")
        name=$(jq -r '.rules['"${i}"'].name' "${file}")
        severity=$(jq -r '.rules['"${i}"'].severity' "${file}")
        status=$(jq -r '.rules['"${i}"'].status' "${file}")
        template_key=$(jq -r '.rules['"${i}"'].templateKey' "${file}")
        type=$(jq -r '.rules['"${i}"'].type' "${file}")
        # rule parameters
        parameters="params="
        for j in $(seq 0 $(($(jq '.rules['"${i}"'].params | length' "${file}")-1)) );
        do
            param_key=$(jq -r '.rules['"$i"'].params['"$j"'].key' "${file}")
            param_value=$(jq -r '.rules['"$i"'].params['"$j"'].defaultValue' "${file}")
            parameters="${parameters}${param_key}=\"${param_value}\";"
        done
        # remove the trailing ;
        parameters="${parameters::-1}"
        # create the rule on the server
        res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                    --data-urlencode "custom_key=${custom_key}" \
                    --data-urlencode "markdown_description=${markdown_description}" \
                    --data-urlencode "name=${name}" \
                    --data-urlencode "severity=${severity}" \
                    --data-urlencode "status=${status}" \
                    --data-urlencode "template_key=${template_key}" \
                    --data-urlencode "type=${type}" \
                    --data-urlencode "${parameters}" \
                    "${SONARQUBE_URL}/api/rules/create")
        key=$(echo "${res}" | jq -r '.rule.key')
        if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
        then
            log "$INFO" "rule ${name} created in SonarQube."
        else
            log "$WARNING" "impossible to create the rule ${name}" "$(echo "${res}" | jq '.errors[].msg')"
        fi

        # for rule information registered using the rule update API (/api/rules/update)
        remediation_fn_base_effort=$(jq -r '.rules['"${i}"'].remFnBaseEffort' "${file}")
        remediation_fn_type=$(jq -r '.rules['"${i}"'].defaultDebtRemFnType' "${file}")
        res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                    --data-urlencode "key=$key" \
                    --data-urlencode "${parameters}" \
                    "${SONARQUBE_URL}/api/rules/update")
        if [ "$(echo "${res}" | jq '(.errors | length)')" != "0" ]
        then
            log "$WARNING"  "impossible to update the rule ${name}" "$(echo "${res}" | jq '.errors[].msg')"
        fi
        res=$(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" \
                    --data-urlencode "key=$key" \
                    --data-urlencode "remediation_fn_base_effort=${remediation_fn_base_effort}" \
                    --data-urlencode "remediation_fn_type=${remediation_fn_type}" \
                    "${SONARQUBE_URL}/api/rules/update")
        if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
        then
            log "$INFO" "rule ${name} updated in SonarQube."
        else
            log "$WARNING"  "impossible to update the rule ${name}" "$(echo "${res}" | jq '.errors[].msg')"
        fi
    done
}

# create_quality_profiles_and_custom_rules
#
# This function imports custom rules and quality profiles from conf/
# to SonarQube server.
create_quality_profiles_and_custom_rules()
{
    # Find all files named "*-rules-template.json" in the folder conf and add rules to SonarQube
    while read -r file
    do
        add_rules "${file}"
    done < <(find conf -name "*-rules-template.json" -type f -print)
    log "$INFO" "added all custom rules."

    # Find all files named "*-quality-profile.xml" in the folder conf and add QP to SonarQube
    while read -r file
    do
        add_quality_profile "${file}"
    done < <(find conf -name "*-quality-profile.xml" -type f -print)
    log "$INFO" "added all quality profiles."
}

# End of functions definition
# ============================================================================ #
# Start script

# Wait for SonarQube to be up
wait_sonarqube_up

# Make sur the database has not already been populated
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

    # Add GPs and rules
    create_quality_profiles_and_custom_rules

    # Add QG
    create_quality_gate
fi

# Tell the user, we are ready
log "$INFO" "ready!"

exit 0
