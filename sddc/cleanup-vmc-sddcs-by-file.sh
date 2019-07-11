#!/bin/bash
# Burke Azbill
# Date: 2019-07-05
# Purpose: This script will cleanup one or more SDDCs in the Org Specified with the name/prefix specified
clear
# Requirements:
# - VMware Cloud on AWS Account
# - bash
# - curl
# - JQ (https://stedolan.github.io/jq/)
# Load common functions
source ../utils/common_functions.sh
# From common_functions.sh
check-jq
# Make sure Auth file is generated/loaded
get-auth-file

# Make sure that the 1 required parameters has been provided:
if [ ${#} -lt 1 ]; then
    echo -e "Usage: \n  $0 [FILENAME] [ORGID] \n"
    echo -e "Optional Parameter Defaults are: \n  ORGID: the value configured in $AUTHFILE \n"
    echo -e "IE:\n  $0 2019-07-10-16-03-cleanup.txt my-org-id-here\n"
    echo -e "Expected Result: \n  SDDCs that match names in that file are deleted but others remain\n"
    exit 1
fi
# Assign variables to values from input params
# Assign default values as needed
FILENAME=$1

if [ -n "$2" ]; then
  # ORGID is set by the auth file, but if provided as 2nd param, use that value instead:
  ORGID=$2
fi

# Warn/Verify Deletion, perform SDDC Deletions
printf "\n\033[1;31mWARNING ! ! The following SDDCs will be deleted if you proceed\033[0m\n" 
cat ${FILENAME}
echo ""
read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # do dangerous stuff
    while read line; do
      SDDCNAME=$(echo $line | cut -d" " -f1)
      if [ ${#SDDCNAME} -gt 3 ]; then
        SDDCID=$(echo $line | cut -d" " -f2)
        echo "Deleting SDDC ${SDDCNAME} - ID: ${SDDCID}...."
        TASKFILE=${SDDCNAME}-delete-task.json
        # Since there is a chance the token could expire, make sure to refresh again:
        # The function will make sure the token is renewed if it is older than 30 min
        getAccessToken
        curl -s -X DELETE https://vmc.vmware.com/vmc/api/orgs/${ORGID}/sddcs/${SDDCID} -H 'Content-Type: application/json' -H "csp-auth-token: ${CSP_ACCESS_TOKEN}" -o ${TASKFILE} &
        sleep 10
      fi
    done < ${FILENAME}
else
  echo "Operation aborted."
  #echo  "Cleaning up temp files"
  #rm *.json
fi

# From common-functions.sh
displayElapsedScriptTime
