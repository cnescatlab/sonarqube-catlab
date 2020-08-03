# Test documentation

## List of scripted integration tests

1. Up
    * file: up.bash
    * purpose: test if the SonarQube server is UP
1. Admin password
    * file: eus_admin.bash
    * purpose: check that no one can log in as admin with the default password (namely "admin")
1. No admin password
    * file: no_password_no_run.bash
    * purpose: check that the container exit before starting the SonarQube server when no admin password is specified or when the admin password is "admin".
1. Plugin check
    * file: check_plugins.bash
    * purpose: check that the plugins listed in the README are installed on the server
1. Quality Gate check
    * file: check_qg.bash
    * purpose: check that the CNES Quality Gate is available on the server and is set as default
1. Quality Profiles check
    * file: check_qp.bash
    * purpose: check that all CNES Quality Profiles are available on the server

TODO: add a test to check that the rules, QPs and QG are not added more than once to the database

## How to run all the tests

Before testing the image, it must be built (see the [README](https://github.com/lequal/sonarqube#how-to-build-the-image)).

To run the tests, the following tools are required:

* `curl`
* `jq`

To run all the tests, use the test script:

```sh
# from the root of the project
$ ./tests/run_tests.bash
```

## How to run a specific test

1. Run a container of the image (see the [user guide](https://github.com/lequal/sonarqube#user-guide))
1. Wait until it is configured
    * The message `[INFO] CNES SonarQube: ready!` is logged.
1. Run a script
    ```sh
    $ ./tests/up.bash
    ```
    * Environnement variables may be modified
        ```sh
        $ SONARQUBE_ADMIN_PASSWORD="password" SONARQUBE_URL="http://localhost:9000" ./tests/up.bash
        ```
1. Test the exit status of the script with `echo $?`
    * zero => success
    * non-zero => failure

## List of options and environment variables used by the tests

Parameters:
* `--no-run`: if this option is specified, the script will not run the container. It will only launch the tests. In this case, make sur to set necessary environment variables.

Environment variables:
* `SONARQUBE_CONTAINER_NAME`: the name to give to the container running the image.
* `SONARQUBE_ADMIN_PASSWORD`: the password of the admin account.
* `SONARQUBE_URL`: URL of `lequal/sonarqube` container if already running without trailing `/` from the host. e.g. http://localhost:9000

## How to add a new test

Tests are just scripts.

To add a test:

1. Create a file under the `tests/` folder
1. Make it executable (with `chmod u+x tests/my_test.bash` for instance)
1. Edit the script.
1. To indicate wether the test has failed or succeed, use the exit status
    * zero => success
    * non-zero => failure
1. Add the test to the [list](#list-of-scripted-integration-tests)

Note that when using `./tests/run_tests.bash` to run the new test alongside the others, only messages on STDERR will by displayed if any.
