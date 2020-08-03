#!/usr/bin/env bash

# User Story:
# As a SonarQube user, I want the plugins listed in the README
# to be installed on the server so that I can use them.

. scripts/functions.bash

sonar_plugins=$(curl -s "$SONARQUBE_URL/api/plugins/installed" \
                | jq -r '.plugins[] | "\(.name)"')

required_plugins=(
    "Checkstyle"
    "Cobertura"
    "Findbugs"
    "Git"
    "GitHub Authentication for SonarQube"
    "JaCoCo"
    "LDAP"
    "PMD"
    "Rules Compliance Index (RCI)"
    "SAML 2.0 Authentication for SonarQube"
    "SonarC#"
    "SonarCSS"
    "SonarFlex"
    "SonarGo"
    "SonarHTML"
    "SonarJS"
    "SonarJava"
    "SonarKotlin"
    "SonarPHP"
    "SonarPython"
    "SonarQube CNES Export Plugin"
    "SonarQube CNES Report"
    "SonarRuby"
    "SonarScala"
    "SonarTS"
    "SonarVB"
    "SonarXML"
    "Svn"
)

for plugin in "${required_plugins[@]}"
do
    if ! echo "$sonar_plugins" | grep -q "$plugin";
    then
        log "$ERROR" "SonarQube server does not contain $plugin" "${0##*/}"
        >&2 echo "curl -s $SONARQUBE_URL/api/plugins/installed"
        >&2 curl -s "$SONARQUBE_URL/api/plugins/installed" | jq
        exit 1
    fi
done

log "$INFO" "all plugins required are installed."
exit 0
