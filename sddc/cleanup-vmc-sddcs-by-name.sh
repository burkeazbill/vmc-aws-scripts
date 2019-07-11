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
OUTFILE="SDDCS_INFO.json"
SUMMARYFILE="sddc-summary.txt"

source ../utils/common_functions.sh
# From common_functions.sh
check-jq
get-auth-file

# Make sure that the 1 required parameters has been provided:
if [ ${#} -lt 1 ]; then
    echo -e "Usage: \n  $0 [SDDCNAME] [ORGID] \n"
    echo -e "Optional Parameter Defaults are: \n  ORGID: the value configured in $AUTHFILE \n"
    echo -e "IE:\n  $0 DEMO- my-org-id-here\n"
    echo -e "Expected Result: \n  DEMO-01, DEMO-02, DEMO-03, DEMO-04 SDDCs are deleted but others remain\n"
    exit 1
fi
# Assign variables to values from input params
# Assign default values as needed
SDDCNAME=$1

if [ -n "$2" ]; then
  # ORGID is set by the auth file, but if provided as 2nd param, use that value instead:
  ORGID=$2
fi

# From common_functions.sh
getAccessToken

# Get JSON file containing all SDDCs info for specified org
curl -s -X GET -H "Content-Type: application/json" -H "csp-auth-token: ${CSP_ACCESS_TOKEN}" -o ${OUTFILE} "https://vmc.vmware.com/vmc/api/orgs/${ORGID}/sddcs/"

# Parse SDDC Info, Warn/Verify Deletion, perform SDDC Deletions
cat ${OUTFILE} | jq -r '.[] | select(.name | test("'${SDDCNAME}.'"; "i")) | "\(.id) Created:\(.created) Provider:\(.provider) Owner:\(.user_name) \(.name)"' > ${SUMMARYFILE}
printf "\n\033[1;31mWARNING ! ! The following SDDCs will be deleted if you proceed\033[0m\n" 
cat ${SUMMARYFILE} | cut -d" " -f2-5
echo ""
read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # do dangerous stuff
    while read line; do
      SDDCNAME=$(echo $line | cut -d" " -f5)
      SDDCID=$(echo $line | cut -d" " -f1)
      echo "Deleting SDDC ${SDDCNAME} - ID: ${SDDCID}...."
      TASKFILE=${SDDCFULLNAME}-delete-task.json
      # Since there is a chance the token could expire, make sure to refresh again:
      getAccessToken
      curl -s -X DELETE https://vmc.vmware.com/vmc/api/orgs/${ORGID}/sddcs/${SDDCID} -H 'Content-Type: application/json' -H "csp-auth-token: ${CSP_ACCESS_TOKEN}" -o ${TASKFILE} &
      sleep 10
    done < ${SUMMARYFILE}
else
  echo "Operation aborted."
  #echo  "Cleaning up temp files"
  #rm ${SUMMARYFILE}
  #rm ${OUTFILE}
  #rm *.json
fi

# From common-functions.sh
displayElapsedScriptTime
