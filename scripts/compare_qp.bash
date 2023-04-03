#!/usr/bin/env bash

# prompt the user for the base URL of their SonarQube instance
read -p "Enter the base URL of your SonarQube instance: " base_url

# prompt the user for their SonarQube user token
read -p "Enter your SonarQube user token: " user_token

# prompt the user for the quality profiles to compare
read -p "Enter the name of the first profile: " profile1_name
read -p "Enter the name of the second profile: " profile2_name

# retrieve the rules of the first quality profile
profile_key1=$(curl -s -u "$user_token:" "$base_url/qualityprofiles/search?qualityProfile=$profile1_name" | jq '.profiles[0].key' | sed 's/"//g')

# retrieve the rules of the second quality profile
profile_key2=$(curl -s -u "$user_token:" "$base_url/qualityprofiles/search?qualityProfile=$profile2_name" | jq '.profiles[0].key' | sed 's/"//g')

profile_rules1=$(curl -s -u "$user_token:" "$base_url/rules/search?activation=true&qprofile=$profile_key1&ps=500" | jq '.rules[]')
profile_rules2=$(curl -s -u "$user_token:" "$base_url/rules/search?activation=true&qprofile=$profile_key2&ps=500" | jq '.rules[]')

# extract all rule keys from each profile
all_rules_key1=$(echo "$profile_rules1" | jq -r '.key')
all_rules_key2=$(echo "$profile_rules2" | jq -r '.key')

echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo -e "Searching the rules in $profile1_name that are not in $profile2_name: \n"
# loop through each rule key in the first quality profile
while read rule1_key; do
  # check if the rule key is present in the second quality profile
  if [[ $(echo "$all_rules_key2" | grep -wc "$rule1_key") -eq 0 ]]; then
    echo "Rule $rule1_key in $profile1_name but not in $profile2_name"
  fi
done <<< "$all_rules_key1"
echo "Done with searching the rules in $profile1_name that are not in $profile2_name"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

echo -e "\n"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo -e "Searching the rules in $profile2_name that are not in $profile1_name: \n"
# loop through each rule key in the second quality profile
while read rule2_key; do
  # check if the rule key is present in the second quality profile
  if [[ $(echo "$all_rules_key1" | grep -wc "$rule2_key") -eq 0 ]]; then
    echo "Rule $rule2_key in $profile2_name but not in $profile1_name"
  fi
done <<< "$all_rules_key2"
echo "Done with searching the rules in $profile2_name that are not in $profile1_name"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"