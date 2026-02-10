# This image is based on a LTS version of SonarQube
FROM sonarqube:25.6.0.109173-community

LABEL maintainer="CATLab"

HEALTHCHECK --interval=5m --start-period=2m \
    CMD test $(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" ${SONARQUBE_URL:-http://localhost:9000}/api/system/health | jq '(.health)') = '"GREEN"'

USER root

# Tools versions
ARG CXX_VERSION=2.2.1
ARG CXX_VERSION_FULL=${CXX_VERSION}.1248
ARG CHECKSTYLE_VERSION=10.23.0
ARG BRANCH_VERSION=25.6.0
ARG FINDBUGS_VERSION=4.5.1
ARG PMD_VERSION=4.0.3
ARG ICODE_VERSION=5.2.0
ARG CNESREPORT_VERSION=5.0.2
ARG YAML_VERSION=1.9.1

# Download SonarQube plugins
ADD https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-${CXX_VERSION}/sonar-cxx-plugin-${CXX_VERSION_FULL}.jar \
    https://github.com/checkstyle/sonar-checkstyle/releases/download/${CHECKSTYLE_VERSION}/checkstyle-sonar-plugin-${CHECKSTYLE_VERSION}.jar \
    https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${BRANCH_VERSION}/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/${FINDBUGS_VERSION}/sonar-findbugs-plugin.jar \
    https://github.com/jensgerdes/sonar-pmd/releases/download/${PMD_VERSION}/sonar-pmd-plugin-${PMD_VERSION}.jar \
    https://github.com/cnescatlab/sonar-icode-cnes-plugin/releases/download/${ICODE_VERSION}/sonar-icode-cnes-plugin-${ICODE_VERSION}.jar \
    https://github.com/cnescatlab/sonar-cnes-report/releases/download/${CNESREPORT_VERSION}/sonar-cnes-report-${CNESREPORT_VERSION}.jar \
    https://github.com/sbaudoin/sonar-yaml/releases/download/v${YAML_VERSION}/sonar-yaml-plugin-${YAML_VERSION}.jar \
    /opt/sonarqube/extensions/plugins/

# Required by the community branch plugin (See https://github.com/mc1arke/sonarqube-community-branch-plugin/tree/1.14.0#installation)
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar=ce"

# Install tools
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    curl jq \
    && rm -rf /var/lib/apt/lists/*

# Copy the config files and scripts into the image
COPY conf/. conf/
COPY scripts/* bin/

# Configure SonarQube
RUN chown -R sonarqube bin/ conf/ extensions/ \
    && chmod u+x -R bin/ \
    # Disable SonarQube telemetry
    && sed -i 's/#sonar\.telemetry\.enable=true/sonar\.telemetry\.enable=false/' /opt/sonarqube/conf/sonar.properties \
    #### Set list of patterns matching Dockerfiles
    && echo 'sonar.lang.patterns.dockerfile=Dockerfile,Dockerfile.*' >> /opt/sonarqube/conf/sonar-scanner.properties

# Switch back to an unpriviledged user
USER sonarqube

CMD [ "./bin/entrypoint.bash" ]
