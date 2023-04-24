#!/usr/bin/env bash

# Check if the required number of parameters are passed
if [ $# -ne 3 ]; then
  echo "Usage: $0 <base_url> <quality_quality_profile_name1> <quality_quality_profile_name2>"
  exit 1
fi

# Check if user_token environment variable is set
if [ -z "$SONAR_USER_TOKEN" ]; then
  echo "Error: SONAR_USER_TOKEN environment variable is not set."
  exit 1
fi

base_url=$1
quality_profile_name1=$2
quality_profile_name2=$3
user_token=$SONAR_USER_TOKEN

# retrieve the rules of the first quality profile
profile_key1=$(curl -s -u "$user_token:" "$base_url/api/qualityprofiles/search?qualityProfile=$quality_profile_name1" | jq '.profiles[0].key' | sed 's/"//g')

# retrieve the rules of the second quality profile
profile_key2=$(curl -s -u "$user_token:" "$base_url/api/qualityprofiles/search?qualityProfile=$quality_profile_name2" | jq '.profiles[0].key' | sed 's/"//g')

profile_rules1=$(curl -s -u "$user_token:" "$base_url/api/rules/search?activation=true&qprofile=$profile_key1&ps=500" | jq '.rules[]')
profile_rules2=$(curl -s -u "$user_token:" "$base_url/api/rules/search?activation=true&qprofile=$profile_key2&ps=500" | jq '.rules[]')

# extract all rule keys from each profile
all_rules_key1=$(echo "$profile_rules1" | jq -r '.key')
all_rules_key2=$(echo "$profile_rules2" | jq -r '.key')

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo -e "Searching the rules in $quality_profile_name1 that are not in $quality_profile_name2: \n"
# loop through each rule key in the first quality profile
while read rule1_key; do
  # check if the rule key is present in the second quality profile
  if [[ $(echo "$all_rules_key2" | grep -wc "$rule1_key") -eq 0 ]]; then
    echo "Rule $rule1_key in $quality_profile_name1 but not in $quality_profile_name2"
  fi
done <<< "$all_rules_key1"
echo -e "\n Done with searching the rules in $quality_profile_name1 that are not in $quality_profile_name2"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

echo -e "\n"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo -e "Searching the rules in $quality_profile_name2 that are not in $quality_profile_name1: \n"
# loop through each rule key in the second quality profile
while read rule2_key; do
  # check if the rule key is present in the second quality profile
  if [[ $(echo "$all_rules_key1" | grep -wc "$rule2_key") -eq 0 ]]; then
    echo "Rule $rule2_key in $quality_profile_name2 but not in $quality_profile_name1"
  fi
done <<< "$all_rules_key2"
echo -e "\nDone with searching the rules in $quality_profile_name2 that are not in $quality_profile_name1"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"