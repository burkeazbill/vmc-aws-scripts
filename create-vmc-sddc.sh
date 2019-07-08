#!/bin/bash
# Burke Azbill
# Date: 2019-07-05
# Purpose: This script will create an SDDC in the Org Specified
clear
# Requirements:
# - VMware Cloud on AWS Account
# - bash
# - curl
# - JQ (https://stedolan.github.io/jq/)
#Start Script timer:
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

# Begin loop to process all requests:
for i in $(seq -f "%02g" 1 ${QTY})
  do
  if [ ${QTY} -gt 1 ]; then
    SDDCFULLNAME=${SDDCNAME}${i}
  fi
  # Prepare params:
  PARAMS="{\"name\": \"${SDDCFULLNAME}\",\"num_hosts\": ${HOSTCOUNT},\"provider\": \"${PROVIDER}\",\"region\": \"${REGION}\"}"
  # echo ${PARAMS}
  echo "Creating SDDC: ${SDDCFULLNAME}"
  curl -s -X POST https://vmc.vmware.com/vmc/api/orgs/${ORGID}/sddcs -H 'Content-Type: application/json' -H "csp-auth-token: ${CSP_ACCESS_TOKEN}" -d "${PARAMS}" -o ${SDDCFULLNAME}-task.json
  sleep 5
done
ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo ""
echo ${ELAPSED}