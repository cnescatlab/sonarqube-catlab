#!/usr/bin/env bash

# User Story:
# As a SonarQube user, I want the plugins listed in the README
# to be installed on the server so that I can use them.

. tests/functions.bash

sonar_plugins=$(curl -s "$SONARQUBE_URL/api/plugins/installed" \
                | jq -r '.plugins[] | "\(.name) - \(.version)"')

required_plugins=(
    "C++ (Community) - 1.3.1 (build 1807)"
    "Checkstyle - 4.21"
    "Cobertura - 1.9.1"
    "Community Branch Plugin - 1.3.2"
    "Findbugs - 3.11.0"
    "Git - 1.8 (build 1574)"
    "GitHub Authentication for SonarQube - 1.5 (build 870)"
    "JaCoCo - 1.0.2 (build 475)"
    "LDAP - 2.2 (build 608)"
    "PMD - 3.2.1"
    "Rules Compliance Index (RCI) - 1.0.1"
    "SAML 2.0 Authentication for SonarQube - 1.2.0 (build 682)"
    "Sonar Frama-C plugin - 2.1.1"
    "Sonar i-Code CNES plugin - 2.0.2"
    "SonarC# - 7.15 (build 8572)"
    "SonarCSS - 1.1.1 (build 1010)"
    "SonarFlex - 2.5.1 (build 1831)"
    "SonarGo - 1.1.1 (build 2000)"
    "SonarHTML - 3.1 (build 1615)"
    "SonarJS - 5.2.1 (build 7778)"
    "SonarJava - 5.13.1 (build 18282)"
    "SonarKotlin - 1.5.0 (build 315)"
    "SonarPHP - 3.2.0.4868"
    "SonarPython - 1.14.1 (build 3143)"
    "SonarQube CNES Export Plugin - 1.2"
    "SonarQube CNES Python Plugin - 1.3"
    "SonarQube CNES Report - 3.2.2"
    "SonarRuby - 1.5.0 (build 315)"
    "SonarScala - 1.5.0 (build 315)"
    "SonarTS - 1.9 (build 3766)"
    "SonarVB - 7.15 (build 8572)"
    "SonarXML - 2.0.1 (build 2020)"
    "Svn - 1.9.0.1295"
    "Custom metrics plugin for Sonarqube - 1.1"
    "gcov - 2.0"
    "Modelsim -1.0"
    "VHDL - 1.8.043"
)

for plugin in "${required_plugins[@]}"
do
    if ! echo "$sonar_plugins" | grep -q "$plugin";
    then
        log "$ERROR" "SonarQube server does not contain $plugin"
        >&2 echo "curl -s $SONARQUBE_URL/api/plugins/installed"
        curl -s "$SONARQUBE_URL/api/plugins/installed" | >&2 jq
        exit 1
    fi
done

log "$INFO" "all plugins required are installed."
exit 0
