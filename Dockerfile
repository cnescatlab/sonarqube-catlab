# This image is based on a LTS version of SonarQube
FROM sonarqube:8.9.6-community

LABEL maintainer="CATLab"

HEALTHCHECK --interval=5m --start-period=2m \
    CMD test $(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" ${SONARQUBE_URL:-http://localhost:9000}/api/system/health | jq '(.health)') = '"GREEN"'

USER root

# Tools versions
ARG ANSIBLE_LINT=2.5.1
ARG CXX_VERSION=2.0.7
ARG CHECKSTYLE_VERSION=8.40
ARG CLOVER_VERSION=4.1
ARG COBERTURA_VERSION=2.0
ARG BRANCH_VERSION=1.8.1
ARG FPGA_VERSION=1.3.0
ARG FINDBUGS_VERSION=4.0.4
ARG MODELSIM_VERSION=1.6.0
ARG PMD_VERSION=3.3.1
ARG SHELLCHECK_VERSION=2.5.0
ARG FRAMAC_VERSION=2.1.1
ARG ICODE_VERSION=3.0.0
ARG CNESREPORT_VERSION=4.1.3
ARG SONARTS_VERSION=2.1.0
ARG VHDLRC_VERSION=3.4
ARG YAML_VERSION=1.7.0

# Download SonarQube plugins
ADD https://github.com/sbaudoin/sonar-ansible/releases/download/v${ANSIBLE_LINT}/sonar-ansible-plugin-${ANSIBLE_LINT}.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-${CXX_VERSION}/sonar-cxx-plugin-${CXX_VERSION}.3119.jar \
    https://github.com/checkstyle/sonar-checkstyle/releases/download/${CHECKSTYLE_VERSION}/checkstyle-sonar-plugin-${CHECKSTYLE_VERSION}.jar \
    https://repo1.maven.org/maven2/io/github/sfeir-open-source/sonar-clover-plugin/${CLOVER_VERSION}/sonar-clover-plugin-${CLOVER_VERSION}.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/${COBERTURA_VERSION}/sonar-cobertura-plugin-${COBERTURA_VERSION}.jar \
    https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${BRANCH_VERSION}/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar \
    https://github.com/Linty-Services/sonar-fpga-metrics-plugin/releases/download/${FPGA_VERSION}/sonar-fpga-metrics-plugin-${FPGA_VERSION}.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/${FINDBUGS_VERSION}/sonar-findbugs-plugin-${FINDBUGS_VERSION}.jar \
    https://github.com/Linty-Services/sonar-modelsim-plugin/releases/download/${MODELSIM_VERSION}/sonar-modelsim-plugin-${MODELSIM_VERSION}.jar \
    https://github.com/jensgerdes/sonar-pmd/releases/download/${PMD_VERSION}/sonar-pmd-plugin-${PMD_VERSION}.jar \
    https://github.com/sbaudoin/sonar-shellcheck/releases/download/v${SHELLCHECK_VERSION}/sonar-shellcheck-plugin-${SHELLCHECK_VERSION}.jar \
    https://github.com/cnescatlab/sonar-frama-c-plugin/releases/download/V${FRAMAC_VERSION}/sonar-frama-c-plugin-${FRAMAC_VERSION}.jar \
    https://github.com/cnescatlab/sonar-icode-cnes-plugin/releases/download/${ICODE_VERSION}/sonar-icode-cnes-plugin-${ICODE_VERSION}.jar \
    https://github.com/cnescatlab/sonar-cnes-report/releases/download/${CNESREPORT_VERSION}/sonar-cnes-report-${CNESREPORT_VERSION}.jar \
    https://github.com/SonarSource/SonarTS/releases/download/${SONARTS_VERSION}.4359/sonar-typescript-plugin-${SONARTS_VERSION}.4362.jar \
    https://github.com/VHDLTool/sonar-VHDLRC/releases/download/v${VHDLRC_VERSION}/sonar-vhdlrc-plugin-${VHDLRC_VERSION}.jar \
    https://github.com/sbaudoin/sonar-yaml/releases/download/v${YAML_VERSION}/sonar-yaml-plugin-${YAML_VERSION}.jar \
    /opt/sonarqube/extensions/plugins/

# Required by the community branch plugin (See https://github.com/mc1arke/sonarqube-community-branch-plugin/tree/1.8.1#installation)
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar=ce"

# Install tools
RUN apk add --no-cache \
       curl \
       jq

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
