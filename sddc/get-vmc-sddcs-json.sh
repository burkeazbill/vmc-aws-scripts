#!/bin/bash
# Burke Azbill
# Date: 2019-07-05
# Purpose: This script will retrieve all SDDCS details available and output them to the OUTFILE: SDDCS_INFO.json
#          The JSON may then be processed by other scripts as desired.
# Requirements:
# - VMware Cloud on AWS Account
# - bash
# - curl
# - JQ (https://stedolan.github.io/jq/)
source ../utils/common_functions.sh
OUTFILE="SDDCS_INFO.json"

# From common_functions.sh
check-jq
# Make sure Auth file is generated/loaded
get-auth-file

if [ -n "$1" ]; then
  # ORGID is set by the auth file, but if provided as param, use that value instead:
  ORGID=$1
fi

getAccessToken
# Get JSON file containing all SDDCs info for specified org
curl -s -X GET -H "Content-Type: application/json" -H "csp-auth-token: ${CSP_ACCESS_TOKEN}" -o ${OUTFILE} "https://vmc.vmware.com/vmc/api/orgs/${ORGID}/sddcs/"

# From common-functions.sh
displayElapsedScriptTime
