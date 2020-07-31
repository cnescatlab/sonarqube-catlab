# CNES SonarQube image \[server\]

![](https://github.com/lequal/sonarqube/workflows/CI/badge.svg?branch=develop)
![](https://github.com/lequal/sonarqube/workflows/CD/badge.svg?branch=develop)

> Docker image for SonarQube with pre-configured plugins and settings by CNES dedicated to Continuous Integration.

This image is a pre-configured SonarQube server image derived from [Docker-CAT](https://github.com/lequal/docker-cat). It contains the same plugins and the same rules for code analysis. It is based on the LTS version of SonarQube.

SonarQube itself is an open source project on GitHub: [SonarSource/sonarqube](https://github.com/SonarSource/sonarqube).

## Motivation of the project

LEQUAL has a need for a tool like Docker-CAT usable in Continuous Integration. In this context, it was decided to develop two Docker images usable in CI:
* A pre-configured SonarQube server with all necessary plugins, rules, quality profiles and quality gates (this project)
* A pre-configured sonar-scanner image that embed all necessary tools also on GitHub: [lequal/sonar-scanner](https://github.com/lequal/sonar-scanner)

## User guide

This image is available on Docker Hub: [lequal/sonarqube](https://hub.docker.com/r/lequal/sonarqube/).

Since inception, this image has been designed to be used in production. Thus, leaving the default admin password (namely "admin") will never be an option. To this extent, a new password for the admin account must be given by setting the environment variable `SONARQUBE_ADMIN_PASSWORD`.

To run the image locally:

```sh
# Recommended options
$ docker run --name lequalsonarqube \
             --rm \
             --stop-timeout 1 \
             -p 9000:9000 \
             -e SONARQUBE_ADMIN_PASSWORD="admin password of your choice" \
             lequal/sonarqube:latest

# To stop (and remove) the container
Ctrl-C
# or
$ docker container stop lequalsonarqube
```

### Use an external database

By default, SonarQube uses an embedded database that can be used for tests but in production using an external database for data persistency is mandatory. The `docker-compose.yml` file shows an example of how to configure an external postgres database. It can be run with:

```sh
$ docker-compose up -d

# To set variables when running the containers
$ LEQUAL_SONARQUBE_VERSION=1.0.0 POSTGRES_PASSWD=secret-passwd SONARQUBE_ADMIN_PASSWORD="a password" docker-compose up -d
```

With an external database, the data used by SonarQube is stored outside of the container. It means that the container may be stopped, restarted, removed and recreated at will.

## SonarQube plugins included

| SonarQube plugin                                  | Version                  | 
|---------------------------------------------------|--------------------------|
| Checkstyle                                        | 4.21                     |
| Cobertura                                         | 1.9.1                    |
| Findbugs                                          | 3.11.0                   |
| Git                                               | 1.8 (build 1574)         |
| GitHub Authentication for SonarQube               | 1.5 (build 870)          |
| JaCoCo                                            | 1.0.2 (build 475)        |
| LDAP                                              | 2.2 (build 608)          |
| PMD                                               | 3.2.1                    |
| Rules Compliance Index (RCI)                      | 1.0.1                    |
| SAML 2.0 Authentication for SonarQube             | 1.1.0 (build 181)        |
| SonarC#                                           | 7.15 (build 8572)        |
| SonarCSS                                          | 1.1.1 (build 1010)       |
| SonarFlex                                         | 2.5.1 (build 1831)       |
| SonarGo                                           | 1.1.1 (build 2000)       |
| SonarHTML                                         | 3.1 (build 1615)         |
| SonarJS                                           | 5.2.1 (build 7778)       |
| SonarJava                                         | 5.13.1 (build 18282)     |
| SonarKotlin                                       | 1.5.0 (build 315)        |
| SonarPHP                                          | 3.2.0.4868               |
| SonarPython                                       | 1.14.1 (build 3143)      |
| SonarQube CNES Export Plugin                      | 1.2                      |
| SonarQube CNES Report                             | 3.2.2                    |
| SonarRuby                                         | 1.5.0 (build 315)        |
| SonarScala                                        | 1.5.0 (build 315)        |
| SonarTS                                           | 1.9 (build 3766)         |
| SonarVB                                           | 7.15 (build 8572)        |
| SonarXML                                          | 2.0.1 (build 2020)       |
| Svn                                               | 1.9.0.1295               |

To update this list run:

```sh
while IFS='|' read -r plugin version
do
    printf "| %-.50s| %-.25s|\n" "$plugin                                                  " "$version                         "
done < <(curl -s http://localhost:9000/api/plugins/installed | jq -r '.plugins[] | "\(.name)|\(.version)"')
```

## Developer's guide

### How to build the image

It is a normal docker image. Thus, it can be built with the following commands.

```sh
# from the root of the project
$ docker build -t lequal/sonarqube .
```

To then run a container with this image see the [user guide](#user-guide).

### How to run tests

Before testing the image, it must be built (see above).

To run the tests, the following tools are required:

* `curl`
* `jq`

To run all the tests, use the test script like this:

```sh
# from the root of the project
$ ./tests/run_tests.bash
```

To run a specific test:
1. Run a container of the image (see the [user guide](#user-guide))
1. Wait until it is configured
    * The message `[INFO] CNES LEQUAL SonarQube: ready!` is logged.
1. Run a script
    ```sh
    $ ./tests/up.bash
    # environnement variables may be modified
    $ SONARQUBE_ADMIN_PASSWORD="password" SONARQUBE_URL="http://localhost:9000" ./tests/up.bash
    ```
1. Test the exit status of the script with `echo $?`
    * zero => success
    * non-zero => failure

### How to write tests

Tests are just scripts. To add a test, create a file under the `tests/` folder and make it executable. Then, edit the script. Success and failure are given by exit statuses. A zero exist status is a success. A non-zero exit status is a failure. Note that when using `./tests/run_tests.bash`, only messages on STDERR will by displayed.

All scripted tests are listed in the [wiki](https://github.com/lequal/sonarqube/wiki#list-of-scripted-integration-tests).

## How to contribute

If you experienced a problem with the image please open an issue. Inside this issue please explain us how to reproduce this issue and paste the log. 

If you want to do a PR, please put inside of it the reason of this pull request. If this pull request fixes an issue please insert the number of the issue or explain inside of the PR how to reproduce this issue.

All details are available in [CONTRIBUTING](https://github.com/lequal/.github/blob/master/CONTRIBUTING.md).

Bugs and feature requests: [issues](https://github.com/lequal/sonarqube/issues)

## License

Licensed under the [GNU General Public License, Version 3.0](https://www.gnu.org/licenses/gpl.txt)

This project is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
