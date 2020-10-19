"""
Automated integration test of CNES SonarQube

Run the tests by launching ``pytest`` from the "tests/" folder.

Pytest documentation: https://docs.pytest.org/en/stable/contents.html
"""

import os
import platform
import re
import subprocess
import time

import docker
import requests


class TestCNESSonarQube:
    """
    This class test the lequal/sonarqube image.
    It does not build it.
    Tests can be parametered with environment variables.

    Environment variables:
        RUN: whether or not to run a container, default "yes", if you
             already have a running container, set it to "no" and provide
             information through the other variables.
        SONARQUBE_CONTAINER_NAME: the name to give to the container running
                                  the image.
        SONARQUBE_ADMIN_PASSWORD: the password of the admin account.
        SONARQUBE_URL: URL of lequal/sonarqube container if already running
                       without trailing / from the host.
                       e.g. http://localhost:9000

    The docstring of each test is the user story it tests.
    """
    # Class variables
    RUN = os.environ.get('RUN', "yes")
    SONARQUBE_CONTAINER_NAME = os.environ.get('SONARQUBE_CONTAINER_NAME', "lequalsonarqube")
    SONARQUBE_ADMIN_PASSWORD = os.environ.get('SONARQUBE_ADMIN_PASSWORD', "adminpassword")
    SONARQUBE_URL = os.environ.get('SONARQUBE_URL', "http://localhost:9000")

    # Functions
    @classmethod
    def wait_cnes_sonarqube_ready(cls, container_name: str, tail = "all"):
        """
        This function waits for SonarQube to be configured by
        the configure.bash script.

        :param container_name: name of the container running lequal/sonarqube
        :param tail: forwarded to docker logs
        """
        docker_client = docker.from_env()
        while b'[INFO] CNES SonarQube: ready!' not in docker_client.containers.get(container_name).logs(tail=tail):
            time.sleep(10)

    @classmethod
    def setup_class(cls):
        """
        Set up the tests
        Launch a container and wait for it to be up
        """
        docker_client = docker.from_env()
        # Launch a CNES SonarQube container
        if cls.RUN == "yes":
            print(f"Launching lequal/sonarqube container (name={cls.SONARQUBE_CONTAINER_NAME})...")
            docker_client.containers.run("lequal/sonarqube:latest",
                name=cls.SONARQUBE_CONTAINER_NAME,
                detach=True,
                auto_remove=True,
                environment={"SONARQUBE_ADMIN_PASSWORD": cls.SONARQUBE_ADMIN_PASSWORD},
                ports={9000: 9000})
        else:
            print(f"Using container {cls.SONARQUBE_CONTAINER_NAME}")
        # Wait for the SonarQube server inside it to be set up
        print(f"Waiting for {cls.SONARQUBE_CONTAINER_NAME} to be up...")
        cls.wait_cnes_sonarqube_ready(cls.SONARQUBE_CONTAINER_NAME)

    @classmethod
    def teardown_class(cls):
        """
        Stop the container
        """
        if cls.RUN == "yes":
            print(f"Stopping {cls.SONARQUBE_CONTAINER_NAME}...")
            docker_client = docker.from_env()
            docker_client.containers.get(cls.SONARQUBE_CONTAINER_NAME).stop()

    def test_up(self):
        """
        As a user, I want the server to be UP so that I can use it.
        """
        status = requests.get(f"{self.SONARQUBE_URL}/api/system/status",
                    auth=("admin", self.SONARQUBE_ADMIN_PASSWORD)).json()['status']
        # Hint: if this test fails, the server might still be starting
        assert status == "UP"

    def test_check_plugins(self):
        """
        As a SonarQube user, I want the plugins listed in the README
        to be installed on the server so that I can use them.
        """
        required_plugins = (
            ("C++ (Community)", "1.3.1 (build 1807)"),
            ("Checkstyle", "4.21"),
            ("Cobertura", "1.9.1"),
            ("Community Branch Plugin", "1.3.2"),
            ("Findbugs", "3.11.0"),
            ("Git", "1.8 (build 1574)"),
            ("GitHub Authentication for SonarQube", "1.5 (build 870)"),
            ("JaCoCo", "1.0.2 (build 475)"),
            ("LDAP", "2.2 (build 608)"),
            ("PMD", "3.2.1"),
            ("Rules Compliance Index (RCI)", "1.0.1"),
            ("SAML 2.0 Authentication for SonarQube", "1.2.0 (build 682)"),
            ("Sonar Frama-C plugin", "2.1.1"),
            ("Sonar i-Code CNES plugin", "2.0.2"),
            ("SonarC#", "7.15 (build 8572)"),
            ("SonarCSS", "1.1.1 (build 1010)"),
            ("SonarFlex", "2.5.1 (build 1831)"),
            ("SonarGo", "1.1.1 (build 2000)"),
            ("SonarHTML", "3.1 (build 1615)"),
            ("SonarJS", "5.2.1 (build 7778)"),
            ("SonarJava", "5.13.1 (build 18282)"),
            ("SonarKotlin", "1.5.0 (build 315)"),
            ("SonarPHP", "3.2.0.4868"),
            ("SonarPython", "1.14.1 (build 3143)"),
            ("SonarQube CNES Export Plugin", "1.2"),
            ("SonarQube CNES Python Plugin", "1.3"),
            ("SonarQube CNES Report", "3.2.2"),
            ("SonarRuby", "1.5.0 (build 315)"),
            ("SonarScala", "1.5.0 (build 315)"),
            ("SonarTS", "1.9 (build 3766)"),
            ("SonarVB", "7.15 (build 8572)"),
            ("SonarXML", "2.0.1 (build 2020)"),
            ("Svn", "1.9.0.1295"),
            ("Custom metrics plugin for Sonarqube","1.1"),
            ("Gcov","2.0"),
            ("Modelsim","1.0"),
            ("VHDL","1.8.043")
        )
        sonar_plugins = requests.get(f"{self.SONARQUBE_URL}/api/plugins/installed").json()['plugins']
        installed_plugins = { plugin['name']: plugin['version'] for plugin in sonar_plugins }
        for name, version in required_plugins:
            # Hint: if this test fails, one or more plugins may be missing or installed with an outdated version
            assert installed_plugins[name] == version

    def test_check_qg(self):
        """
        As a SonarQube user, I want the SonarQube server to have the CNES
        Quality Gate configured and set as default so that I can use it.
        """
        quality_gates = requests.get(f"{self.SONARQUBE_URL}/api/qualitygates/list").json()['qualitygates']
        cnes_quality_gates = [ gate for gate in quality_gates if gate['name'] == "CNES" ]
        # Hint: if one of these tests fails, the CNES Quality Gate may not have been added correctly, check the container logs
        assert cnes_quality_gates # not empty
        assert cnes_quality_gates[0]['isDefault']

    def test_check_qp(self):
        """
        As a SonarQube user, I want the SonarQube server to have the
        CNES Quality Profiles available so that I can use them.
        """
        required_quality_profiles = (
            "CNES_JAVA_A",
            "CNES_JAVA_B",
            "CNES_JAVA_C",
            "CNES_JAVA_D",
            "CNES_PYTHON_A",
            "CNES_PYTHON_B",
            "CNES_PYTHON_C",
            "CNES_PYTHON_D",
            "CNES_CPP_A",
            "CNES_CPP_B",
            "CNES_CPP_C",
            "CNES_CPP_D",
            "CNES_C_A",
            "CNES_C_B",
            "CNES_C_C",
            "CNES_C_D",
            "CNES_C_EMBEDDED_A",
            "CNES_C_EMBEDDED_B",
            "CNES_C_EMBEDDED_C",
            "CNES_C_EMBEDDED_D"
        )
        quality_profiles = requests.get(f"{self.SONARQUBE_URL}/api/qualityprofiles/search").json()['profiles']
        cnes_quality_profiles = [ qp['name'] for qp in quality_profiles if re.match(r'CNES_\w+_[ABCD]', qp['name']) ]
        for profile in required_quality_profiles:
            # Hint: if this test fails, one or more Quality Profiles may be missing, check the container logs
            assert profile in cnes_quality_profiles

    def test_eus_admin(self):
        """
        Evil User Story:
        As a hacker, I want to use the default admin password ("admin")
        to log in as admin.
        """
        status = requests.post(f"{self.SONARQUBE_URL}/api/authentication/login",
                    auth=("admin", "admin"),
                    data={"login": "admin", "password": "admin"}).status_code
        # Hint: if this test fails, a hacker may have logged in (HTTP 200) or crash the server (HTTP 500+)
        assert status == 401 # Unauthorized


def test_no_config_twice():
    """
    As a SonarQube user, I want the configuration of the server
    not to be executed if the server has already been configured
    so that the database is not populated more than once.
    """
    # On Linux, max_map_count must be at least 262144 to run this test
    if platform.system() == 'Linux':
        proc_stdout = subprocess.run(["sysctl", "-a"], check=True, capture_output=True).stdout
        max_map_count = int(re.findall('vm.max_map_count = [0-9]+', str(proc_stdout))[0].split(' = ')[1])
        # Hint: if this test fails, run: sudo sysctl -w vm.max_map_count=262144
        assert max_map_count >= 262144
    docker_client = docker.from_env()
    lequalsonarqube_container_name="lequalsonarqube-compose"
    # Use the compose file with an external database
    print("Starting the service (sonarqube and postgres)...")
    subprocess.run(["docker-compose", "up", "-d"], check=True, capture_output=True)
    # Wait for the SonarQube container to be configured
    TestCNESSonarQube.wait_cnes_sonarqube_ready(lequalsonarqube_container_name)
    # Restart the SonarQube server but not the database
    print("Restarting SonarQube server...")
    docker_client.containers.get(lequalsonarqube_container_name).restart()
    time.sleep(30)
    TestCNESSonarQube.wait_cnes_sonarqube_ready(lequalsonarqube_container_name, tail=10)
    # Check SonarQube logs
    config_logs = docker_client.containers.get(lequalsonarqube_container_name).logs()
    subprocess.run(["docker-compose", "down"], check=True, capture_output=True)
    docker_client.volumes.get("tests_test_volume_compose_sonarqube_data").remove()
    docker_client.volumes.get("tests_test_volume_compose_sonarqube_extensions").remove()
    docker_client.volumes.get("tests_test_volume_compose_sonarqube_logs").remove()
    docker_client.volumes.get("tests_test_volume_compose_postgresql").remove()
    docker_client.volumes.get("tests_test_volume_compose_postgresql_data").remove()
    # Hint: if this test fails, the server may have been reconfigured when not needed or the test did not wait long enough for the expected message to be logged
    assert b"[INFO] CNES SonarQube: The database has already been filled with CNES configuration. Not adding anything." in config_logs

def test_no_password_no_run():
    """
    As a SonarQube user, I want the container not to start when I forget to
    set the admin password so that the default admin password cannot be used.
    """
    docker_client = docker.from_env()
    for password in ("", "admin"):
        params = {"name": "tmp", "detach": True}
        if password:
            params['environment'] = {"SONARQUBE_ADMIN_PASSWORD": password}
        docker_client.containers.run("lequal/sonarqube:latest", **params)
        time.sleep(3)
        output = docker_client.containers.get("tmp").logs()
        docker_client.containers.get("tmp").remove(force=True)
        # Hint: if this test fails, the server may have started with the default admin password or the test did not wait long enough for the expected message to be logged
        assert b"Failed to start CNES SonarQube." in output
