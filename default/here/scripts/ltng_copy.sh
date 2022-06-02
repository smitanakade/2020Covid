# AUTHOR: Michael Manoussakis
# DATE:   15/10/2020
# Empties email templates directory, then copies specified lightning templates to that directory for deployment

### USAGE
#   Before running, set up config file "./config/ltng_templates.txt" with one filename per line. Do not include file extensions.
#   EXAMPLE FILENAME: End_of_isolation_alternative_accomodtion_approved_1602232726012
#   Run script with no parameters from root directory
#   EXAMPLE COMMAND: ./scripts/ltng_copy.sh


#!/bin/bash
echo '--- Emptying "./force-app/main/default/email/unfiled$public/" ---'
rm ./force-app/main/default/email/unfiled\$public/*

echo '--- Starting copy from "./ltng-templates/" to "./force-app/main/default/email/unfiled$public/" ---'

while read filename; do
    echo "copying $filename"
    cp ./ltng-templates/${filename}.* './force-app/main/default/email/unfiled$public/'
done < ./config/ltng_templates.txt

# EXAMPLE mv ./ltng-templates/Case_at_a_healthcare_setting_1599728696834.* ./force-app/main/default/email/unfiled\$public/

echo "--- Copy complete ---"
