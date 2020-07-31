# This image is based on a LTS version of SonarQube
FROM sonarqube:7.9.3-community

LABEL maintainer="L-lequal@cnes.fr"

HEALTHCHECK --interval=5m --start-period=2m \
    CMD test $(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" ${SONARQUBE_URL:-http://localhost:9000}/api/system/health | jq '(.health)') = '"GREEN"'

USER root

# Install tools
# hadolint ignore=DL3008
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
       curl \
       jq \
    && rm -rf /var/lib/apt/lists/*

# Copy the config files into the image
COPY conf/* lequalconf/
COPY scripts/* bin/

# Configure SonarQube
RUN chown -R sonarqube:sonarqube bin/ lequalconf/ \
    && chmod u+x -R bin/ lequalconf/ \
    # Disable SonarQube telemetry
    && sed -i 's/#sonar\.telemetry\.enable=true/sonar\.telemetry\.enable=false/' /opt/sonarqube/conf/sonar.properties

# Switch back to an unpriviledged user
USER sonarqube

CMD [ "./bin/entrypoint.bash" ]
