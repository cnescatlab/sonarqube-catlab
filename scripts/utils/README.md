# sonarqube-utils
This repository aims to provide some useful scripts for developers that want to contribute in the cnescatlab repository.
Check the use of the scripts below, it can be useful for you.

We can't ensure that the scripts work in all situations. This project is offered "as-is", without warranty, and we disclaim liability
for damages resulting from using the projects.

## compare_qp
This script compare SonarQube Quality Profiles and lists the rules that are present in one profile but not the other. The script prompts the user for the base URL of their SonarQube instance, their SonarQube user token, and the names of the two quality profiles to be compared.

Requirements:

    Bash shell
    curl
    jq (a lightweight and flexible command-line JSON processor)

Usage:

    Make the script executable: chmod +x compare_sonar_qp.sh
    Set the SONAR_USER_TOKEN environment variable: export SONAR_USER_TOKEN=<your_user_token>
    Run the script with the required parameters: ./compare_sonar_profiles.sh <base_url> <quality_profile1_name> <quality_profile2_name>

How it works:

    The script prompts the user for the base URL of their SonarQube instance, their SonarQube user token, and the names of the two quality profiles to be compared.
    It retrieves the rule keys for each quality profile by making API calls to the SonarQube instance and uses the jq command to parse the JSON response.
    The script extracts all rule keys from the retrieved rules of each quality profile.
    It compares the rule keys between the two profiles and outputs the rules that are present in one profile but not the other.

Output:
The script will output the rules that are present in the first quality profile but not the second, followed by the rules present in the second quality profile but not the first. The output will be formatted as follows:

```bash
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Searching the rules in profile1_name that are not in profile2_name:

Rule rule_key in profile1_name but not in profile2_name
...
Done with searching the rules in profile1_name that are not in profile2_name
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Searching the rules in profile2_name that are not in profile1_name:

Rule rule_key in profile2_name but not in profile1_name
...
Done with searching the rules in profile2_name that are not in profile1_name
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
```

This information can be helpful for teams looking to align their quality profiles or identify discrepancies between them.