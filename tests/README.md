# Test documentation

## List of integration tests

1. Up
    * function: test_up
    * purpose: test if the SonarQube server is UP
1. Plugin check
    * function: test_check_plugins
    * purpose: check that the plugins listed in the README are installed on the server with the right version
1. Quality Gate check
    * function: test_check_qg
    * purpose: check that the CNES Quality Gate is available on the server and is set as default
1. Quality Profiles check
    * function: test_check_qp
    * purpose: check that all CNES Quality Profiles are available on the server
1. Admin password
    * function: test_eus_admin
    * purpose: check that no one can log in as admin with the default password (namely "admin")
1. No admin password
    * function: test_no_password_no_run
    * purpose: check that the container exit before starting the SonarQube server when no admin password is specified or when the admin password is "admin"
1. No unnecessary reconfiguration
    * function: test_no_config_twice
    * purpose: check that the rules, QPs and QG are not added more than once to the database
    * requirements: run `sudo sysctl -w vm.max_map_count=262144` before running this test

## How to run all the tests

Before testing the image, it must be built (see the [README](https://github.com/cnescatlab/sonarqube#how-to-build-the-image)).

To run the tests, we use [pytest](https://docs.pytest.org/en/stable/) with `Python 3.8` and the dependencies listed in _requirements.txt_. It is advised to use a virtual environment to run the tests.

```sh
# To run all the tests
$ cd tests/
$ pytest
```

```sh
# One way to set up a virtual environment (optional)
$ cd tests/
$ virtualenv -p python3.8 env
$ . env/bin/activate
$ pip install -r requirements.txt
```

## How to run a specific test

1. Activate the virtual environment (if any)
1. Run a container of the image (see the [user guide](https://github.com/cnescatlab/sonarqube#user-guide))
1. Wait until it is configured
    * The message `[INFO] CNES SonarQube: ready!` is logged.
1. Run a specific test with `pytest` and specify some environment variables
    ```sh
    $ RUN=no SONARQUBE_ADMIN_PASSWORD="password" pytest -k "<name of the test>"
    ```

## List of environment variables used by the tests

* `RUN`: "no" not to run a container at the start of the tests, the default is to run one.
* `SONARQUBE_CONTAINER_NAME`: the name to give to the container running the image.
* `SONARQUBE_ADMIN_PASSWORD`: the password of the admin account.
* `SONARQUBE_URL`: URL of `lequal/sonarqube` container if already running without trailing `/` from the host. e.g. http://localhost:9000
