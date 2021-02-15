# This image is based on a LTS version of SonarQube
FROM sonarqube:7.9.4-community

LABEL maintainer="CATLab <catlab@cnes.fr>"

HEALTHCHECK --interval=5m --start-period=2m \
    CMD test $(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" ${SONARQUBE_URL:-http://localhost:9000}/api/system/health | jq '(.health)') = '"GREEN"'

USER root

# Download SonarQube plugins
ADD https://github.com/cnescatlab/sonar-cnes-export-plugin/releases/download/v1.2.0/sonar-cnes-export-plugin-1.2.jar \
    https://github.com/cnescatlab/sonar-cnes-report/releases/download/3.3.0/sonar-cnes-report.jar \
    https://github.com/willemsrb/sonar-rci-plugin/releases/download/sonar-rci-plugin-1.0.1/sonar-rci-plugin-1.0.1.jar \
    https://github.com/jensgerdes/sonar-pmd/releases/download/3.2.1/sonar-pmd-plugin-3.2.1.jar \
    https://github.com/checkstyle/sonar-checkstyle/releases/download/4.21/checkstyle-sonar-plugin-4.21.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/1.9.1/sonar-cobertura-plugin-1.9.1.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/3.11.0/sonar-findbugs-plugin-3.11.0.jar \
    https://github.com/cnescatlab/sonar-icode-cnes-plugin/releases/download/2.0.2/sonar-icode-cnes-plugin-2.0.2.jar \
    https://github.com/cnescatlab/sonar-cnes-python-plugin/releases/download/1.3/sonar-cnes-python-plugin-1.3.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-1.3.1/sonar-cxx-plugin-1.3.1.1807.jar \
    https://github.com/cnescatlab/sonar-frama-c-plugin/releases/download/V2.1.1/sonar-frama-c-plugin-2.1.1.jar \
    https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/1.3.2/sonarqube-community-branch-plugin-1.3.2.jar \
    https://github.com/cnescatlab/sonar-hadolint-plugin/releases/download/1.0.0/sonar-hadolint-plugin-1.0.0.jar \
    /opt/sonarqube/extensions/plugins/

# Install tools
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
       curl=7.64* \
       jq=1.5* \
    && rm -rf /var/lib/apt/lists/* \
    # Required by the community branch plugin (See https://github.com/mc1arke/sonarqube-community-branch-plugin/tree/1.3.2#installation)
    && ln -s /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-1.3.2.jar /opt/sonarqube/lib/common/sonarqube-community-branch-plugin-1.3.2.jar

# Copy the config files and scripts into the image
COPY conf/* conf/
COPY scripts/* bin/

# Configure SonarQube
RUN chown -R sonarqube:sonarqube bin/ conf/ extensions/ \
    && chmod u+x -R bin/ \
    # Disable SonarQube telemetry
    && sed -i 's/#sonar\.telemetry\.enable=true/sonar\.telemetry\.enable=false/' /opt/sonarqube/conf/sonar.properties \
    #### Set list of patterns matching Dockerfiles
    && echo 'sonar.lang.patterns.dockerfile=Dockerfile,Dockerfile.*' >> /opt/sonarqube/conf/sonar-scanner.properties

# Switch back to an unpriviledged user
USER sonarqube

CMD [ "./bin/entrypoint.bash" ]
