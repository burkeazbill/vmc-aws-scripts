#!/bin/bash
# Burke Azbill
# Date: 2019-07-05
# Purpose: This script will create one or more SDDCs in the Org Specified
clear
# Requirements:
# - VMware Cloud on AWS Account
# - bash
# - curl
# - JQ (https://stedolan.github.io/jq/)
source ../utils/common_functions.sh
# From common_functions.sh
check-jq
# Make sure Auth file is generated/loaded
get-auth-file

# Make sure that the 2 required parameters have been provided:
if [ ${#} -lt 2 ]; then
    echo -e "Usage: \n  $0 [ORGID] [SDDCNAME] ([HOSTCOUNT]) ([PROVIDER: AWS or ZEROCLOUD]) ([QTY]) ([REGION])\n"
    echo -e "Optional Parameter Defaults are: \n  HOSTCOUNT: 1, PROVIDER: ZEROCLOUD, QTY: 1, REGION: US_WEST_2\n"
    echo -e "IE:\n  $0 my-org-id-here Prod-SDDC 4 ZEROCLOUD 4 US_WEST_2\n"
    echo -e "Expected Result: \n  Prod-SDDC01, Prod-SDDC02, Prod-SDDC03, Prod-SDDC04 4-host ZEROCLOUD clusters deployed to US_WEST_2\n"
    exit 1
fi
# Assign variables to values from input params
# Assign default values as needed
ORGID=$1
SDDCNAME=$2
if [ -n "$3" ]; then
  HOSTCOUNT=$3
else
  HOSTCOUNT=1
fi
if [ -n "$4" ]; then
  # Only match on AWS or ZEROCLOUD
  if [[ "$4" =~ (AWS|ZEROCLOUD)$ ]]; then
    PROVIDER="$4"
  else
    # Default to ZEROCLOUD if invalid value is provided
    PROVIDER="ZEROCLOUD"
  fi
else
  # Default to ZEROCLOUD if no value is provided
  PROVIDER="ZEROCLOUD"
fi
if [ -n "$5" ]; then
  QTY=$5
else
  QTY=1
fi
if [ -n "$6" ]; then
  REGION=$6
else
  REGION="US_WEST_2"
fi

# Begin loop to process all requests:
for i in $(seq -f "%02g" 1 ${QTY})
  do
  if [ ${QTY} -gt 1 ]; then
    SDDCFULLNAME=${SDDCNAME}${i}
  else
    SDDCFULLNAME=${SDDCNAME}
  fi
  # Prepare params:
  PARAMS="{\"name\": \"${SDDCFULLNAME}\",\"num_hosts\": ${HOSTCOUNT},\"provider\": \"${PROVIDER}\",\"region\": \"${REGION}\"}"
  # echo ${PARAMS}
  echo "Creating SDDC: ${SDDCFULLNAME}"
  TASKFILE=${SDDCFULLNAME}-task.json
  getAccessToken
  curl -s -X POST https://vmc.vmware.com/vmc/api/orgs/${ORGID}/sddcs -H 'Content-Type: application/json' -H "csp-auth-token: ${CSP_ACCESS_TOKEN}" -d "${PARAMS}" -o ${TASKFILE} &
  sleep 10
  ERROR_MESSAGE=$(jq -r .error_messages ${TASKFILE})
  RESOURCE_ID=$(jq -r .resource_id ${TASKFILE})
  if [[ "${#RESOURCE_ID}" -gt 4 ]]; then
    echo "Success! New SDDC ID: "${RESOURCE_ID}
  else
    echo "Error! : "${ERROR_MESSAGE}
  fi
done

# From common-functions.sh
displayElapsedScriptTime
