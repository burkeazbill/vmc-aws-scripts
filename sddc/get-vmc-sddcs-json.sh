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

SECONDS=0
# Load Private file for ORG and TOKEN
# Contents of the file should be as follows:
# export ORGID="ORGANIZATION-ID-FROM-DEVELOPER-CENTER-OVERVIEW"
# export REFRESH_TOKEN="YOUR-VMWARE-CLOUD-SERVICES-API-TOKEN"
AUTHFILE=~/.vmc-aws-auth.txt

if test -f "$AUTHFILE"; then
  source ${AUTHFILE}
else
  echo $AUTHFILE not found! Please answer the following questions to create it:
  read -p "Please provide your Organization ID: " userorgid
  read -p "Please provide your Refresh Token: " userrefreshtoken
  read -p "Please enter your Organization Name: " userorgname
  # Now generate the file:
  cat > $AUTHFILE <<EOF
# Organization Name: $userorgname
export ORGID="$userorgid"
export REFRESH_TOKEN="$userrefreshtoken"
EOF
  echo $AUTHFILE created:
  # cat $AUTHFILE
  source ${AUTHFILE}
fi

OUTFILE="SDDCS_INFO.json"

# Confirm that the "jq" CLI is available
type jq > /dev/null 2>&1
if [ $? -eq 1 ]; then
    echo "It does not look like you have jq installed. This script uses jq to parse the JSON output"
    echo "Please install jq https://stedolan.github.io/jq/ in order to proceed"
    exit 1
    # else
    # echo "jq was found!"
fi
# Retrieve Access token:
RESULTS=$(curl -s -X POST -H "application/x-www-form-urlencoded" "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" -d "refresh_token=$REFRESH_TOKEN")
CSP_ACCESS_TOKEN=$(echo $RESULTS | jq -r .access_token)
# Get JSON file containing all SDDCs info for specified org
curl -s -X GET -H "Content-Type: application/json" -H "csp-auth-token: ${CSP_ACCESS_TOKEN}" -o ${OUTFILE} "https://vmc.vmware.com/vmc/api/orgs/${ORGID}/sddcs/"
ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo ${ELAPSED}