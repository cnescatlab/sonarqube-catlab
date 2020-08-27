#!/usr/bin/env bash

# User Story:
# As a SonarQube user, I want the configuration of the server
# not to be executed if the server has already been configured
# so that the database is not populated more than once.

. tests/functions.bash

# Make sur max_map_count is high enough
# to prevent the error "max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]"
max_map_count=$(sysctl -a 2>&1 | grep vm.max_map_count | sed -r -e 's/vm.max_map_count = ([0-9]+)/\1/')
if [ "$max_map_count" -lt 262144 ]
then
    log "$ERROR" "The test cannot be run because the max_map_count is to low, increase it to at least 262144 by running: sudo sysctl -w vm.max_map_count=262144"
    exit 1
fi

lequalsonarqube_container_name="lequalsonarqube-compose"

# Use the compose file with an external database
docker-compose -f tests/docker-compose.yml up -d 2>&1

# Wait for the SonarQube container to be configured
wait_cnes_sonarqube_ready "$lequalsonarqube_container_name" 2>&1

# Restart the SonarQube server but not the database
log "$INFO" "Restarting SonarQube server."
docker container restart "$lequalsonarqube_container_name" 2>&1
sleep 30

# Wait for the SonarQube container to be UP again
while ! docker container logs --tail 10 "$lequalsonarqube_container_name" 2>&1 | grep -q '\[INFO\] CNES SonarQube: ready!';
do
    log "$INFO" "Waiting for CNES SonarQube to be ready."
    sleep 5
done

# Check SonarQube logs
docker container logs "$lequalsonarqube_container_name" \
        |& grep -q "\[INFO\] CNES SonarQube: The database has already been filled with CNES configuration. Not adding anything."
success=$?
if [ "$success" != "0" ]
then
    log "$ERROR" "SonarQube server was reconfigured. It should not have been."
    >&2 docker container logs "$lequalsonarqube_container_name"
fi

# Shut down SonarQube and Postgres
docker-compose -f tests/docker-compose.yml down 2>&1
# Remove volumes (or they will be used for next run of this test)
docker volume rm tests_test_volume_compose_sonarqube_data 2>&1
docker volume rm tests_test_volume_compose_sonarqube_extensions 2>&1
docker volume rm tests_test_volume_compose_sonarqube_logs 2>&1
docker volume rm tests_test_volume_compose_postgresql 2>&1
docker volume rm tests_test_volume_compose_postgresql_data 2>&1

if [ "$success" != "0" ]
then
    exit 1
fi

log "$INFO" "SonarQube is not reconfigured if already configured."
exit 0
