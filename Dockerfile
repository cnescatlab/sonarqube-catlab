# This image is based on a LTS version of SonarQube
FROM sonarqube:9.9.1-community

LABEL maintainer="CATLab"

HEALTHCHECK --interval=5m --start-period=2m \
    CMD test $(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" ${SONARQUBE_URL:-http://localhost:9000}/api/system/health | jq '(.health)') = '"GREEN"'

USER root

# Tools versions
ARG ANSIBLE_LINT=2.5.1
ARG CXX_VERSION=2.1.0
ARG CXX_VERSION_FULL=${CXX_VERSION}.428
ARG CHECKSTYLE_VERSION=10.9.3
ARG CLOVER_VERSION=4.1
ARG COBERTURA_VERSION=2.0
ARG BRANCH_VERSION=1.14.0
ARG FINDBUGS_VERSION=4.2.3
ARG PMD_VERSION=3.4.0
ARG SHELLCHECK_VERSION=2.5.0
ARG ICODE_VERSION=3.1.0
ARG CNESREPORT_VERSION=4.2.0
ARG SONARTS_VERSION_REPO=2.1.0.4359
ARG SONARTS_VERSION=2.1.0.4362
ARG VHDLRC_VERSION=3.4
ARG YAML_VERSION=1.7.0

# Download SonarQube plugins
ADD https://github.com/sbaudoin/sonar-ansible/releases/download/v${ANSIBLE_LINT}/sonar-ansible-plugin-${ANSIBLE_LINT}.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-${CXX_VERSION}/sonar-cxx-plugin-${CXX_VERSION_FULL}.jar \
    https://github.com/checkstyle/sonar-checkstyle/releases/download/${CHECKSTYLE_VERSION}/checkstyle-sonar-plugin-${CHECKSTYLE_VERSION}.jar \
    https://repo1.maven.org/maven2/io/github/sfeir-open-source/sonar-clover-plugin/${CLOVER_VERSION}/sonar-clover-plugin-${CLOVER_VERSION}.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/${COBERTURA_VERSION}/sonar-cobertura-plugin-${COBERTURA_VERSION}.jar \
    https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${BRANCH_VERSION}/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/${FINDBUGS_VERSION}/sonar-findbugs-plugin-${FINDBUGS_VERSION}.jar \
    https://github.com/jensgerdes/sonar-pmd/releases/download/${PMD_VERSION}/sonar-pmd-plugin-${PMD_VERSION}.jar \
    https://github.com/sbaudoin/sonar-shellcheck/releases/download/v${SHELLCHECK_VERSION}/sonar-shellcheck-plugin-${SHELLCHECK_VERSION}.jar \
    https://github.com/cnescatlab/sonar-icode-cnes-plugin/releases/download/${ICODE_VERSION}/sonar-icode-cnes-plugin-${ICODE_VERSION}.jar \
    https://github.com/cnescatlab/sonar-cnes-report/releases/download/${CNESREPORT_VERSION}/sonar-cnes-report-${CNESREPORT_VERSION}.jar \
    https://github.com/SonarSource/SonarTS/releases/download/${SONARTS_VERSION_REPO}/sonar-typescript-plugin-${SONARTS_VERSION}.jar \
    https://github.com/VHDLTool/sonar-VHDLRC/releases/download/v${VHDLRC_VERSION}/sonar-vhdlrc-plugin-${VHDLRC_VERSION}.jar \
    https://github.com/sbaudoin/sonar-yaml/releases/download/v${YAML_VERSION}/sonar-yaml-plugin-${YAML_VERSION}.jar \
    /opt/sonarqube/extensions/plugins/

# Required by the community branch plugin (See https://github.com/mc1arke/sonarqube-community-branch-plugin/tree/1.8.1#installation)
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar=ce"

# Install tools
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    curl=7.81.0-* \
    jq=1.6-* \
    && rm -rf /var/lib/apt/lists/*

# Copy the config files and scripts into the image
COPY conf/. conf/
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
