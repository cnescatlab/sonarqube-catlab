# This image is based on a LTS version of SonarQube
FROM sonarqube:8.9-community

LABEL maintainer="CATLab <catlab@cnes.fr>"

HEALTHCHECK --interval=5m --start-period=2m \
    CMD test $(curl -su "admin:$SONARQUBE_ADMIN_PASSWORD" ${SONARQUBE_URL:-http://localhost:9000}/api/system/health | jq '(.health)') = '"GREEN"'

USER root

ARG BRANCH_PLUGIN_VERSION=1.8.1

# Download SonarQube plugins
ADD https://github.com/cnescatlab/sonar-cnes-export-plugin/releases/download/v1.2.0/sonar-cnes-export-plugin-1.2.jar \
    https://github.com/cnescatlab/sonar-cnes-report/releases/download/4.0.0/sonar-cnes-report.jar \
    https://github.com/willemsrb/sonar-rci-plugin/releases/download/sonar-rci-plugin-1.0.1/sonar-rci-plugin-1.0.1.jar \
    https://github.com/jensgerdes/sonar-pmd/releases/download/3.3.1/sonar-pmd-plugin-3.3.1.jar \
    https://github.com/checkstyle/sonar-checkstyle/releases/download/8.40/checkstyle-sonar-plugin-8.40.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/2.0/sonar-cobertura-plugin-2.0.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/4.0.4/sonar-findbugs-plugin-4.0.4.jar \
    https://github.com/cnescatlab/sonar-icode-cnes-plugin/releases/download/2.0.2/sonar-icode-cnes-plugin-2.0.2.jar \
    https://github.com/cnescatlab/sonar-cnes-python-plugin/releases/download/1.3/sonar-cnes-python-plugin-1.3.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-1.3.2/sonar-cxx-plugin-1.3.2.1853.jar \
    https://github.com/cnescatlab/sonar-frama-c-plugin/releases/download/V2.1.1/sonar-frama-c-plugin-2.1.1.jar \
    https://github.com/VHDLTool/sonar-VHDLRC/releases/download/v3.4/sonar-vhdlrc-plugin-3.4.jar \
    https://github.com/Linty-Services/sonar-modelsim-plugin/releases/download/1.6.0/sonar-modelsim-plugin-1.6.0.jar \
    https://github.com/Linty-Services/sonar-fpga-metrics-plugin/releases/download/1.3.0/sonar-fpga-metrics-plugin-1.3.0.jar \
    https://github.com/Linty-Services/sonar-gcov-plugin/releases/download/1.4.0/sonar-gcov-plugin-1.4.0.jar \
    https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${BRANCH_PLUGIN_VERSION}/sonarqube-community-branch-plugin-${BRANCH_PLUGIN_VERSION}.jar \
    https://github.com/cnescatlab/sonar-hadolint-plugin/releases/download/1.0.0/sonar-hadolint-plugin-1.0.0.jar \
    https://github.com/sbaudoin/sonar-ansible/releases/download/v2.5.1/sonar-ansible-plugin-2.5.1.jar \
    https://github.com/sbaudoin/sonar-ansible/releases/download/v2.5.1/sonar-ansible-extras-plugin-2.5.1.jar \
    https://github.com/sbaudoin/sonar-yaml/releases/download/v1.7.0/sonar-yaml-plugin-1.7.0.jar \
    /opt/sonarqube/extensions/plugins/

# Required by the community branch plugin (See https://github.com/mc1arke/sonarqube-community-branch-plugin/tree/1.8.1#installation)
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_PLUGIN_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_PLUGIN_VERSION}.jar=ce"

# Install tools
RUN apk add --no-cache \
       curl \
       jq \
    && rm -rf /var/cache/apk/*

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
