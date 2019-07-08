#!/bin/bash
# Burke Azbill
# Date: 2019-07-05
# Purpose: This script will display a summary for the given SDDC
#
# Requirements:
# - VMware Cloud on AWS Account
# - bash
# - curl
# - JQ (https://stedolan.github.io/jq/)
#
# A majority of this script is credited to William Lam:
# https://github.com/lamw/vghetto-scripts/blob/master/shell/vmc_sddc_summary.sh
# My Changes: reduce CLI params to 1: SDDCID
# - Move ORGID and REFRESH_TOKEN into a text auth file kept in user home directory
# - Name the output file SDDC_INFO.json 
# - Changed availability zone source

# Make sure that an SDDC ID has been provided:
if [ ${#} -ne 1 ]; then
    echo -e "Usage: \n\t$0 [SDDCID]\n"
    exit 1
fi
# Assign the SDDC ID to a variable:
SDDCID=$1
OUTFILE="SDDC_INFO.json"
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
curl -s -X GET -H "Content-Type: application/json" -H "csp-auth-token: ${CSP_ACCESS_TOKEN}" -o ${OUTFILE} "https://vmc.vmware.com/vmc/api/orgs/${ORGID}/sddcs/${SDDCID}"

SDDC_NAME=$(cat ${OUTFILE}|jq -r .name)
SDDC_ID=$(cat ${OUTFILE}|jq -r .id)
USER_NAME=$(cat ${OUTFILE}|jq -r .user_name)
SDDC_VERSION=$(cat ${OUTFILE}|jq -r .resource_config.sddc_manifest.vmc_version)
CREATE_DATE=$(cat ${OUTFILE}|jq -r .created)
DEPLOYMENT_TYPE=$(cat ${OUTFILE}|jq -r .resource_config.deployment_type)
REGION=$(cat ${OUTFILE}|jq -r .resource_config.region)
AVAILABILITY_ZONE=$(cat ${OUTFILE}|jq -r .resource_config.agent.availability_zone_info_id)
INSTANCE_TYPE=$(cat ${OUTFILE}|jq -r .resource_config.sddc_manifest.esx_ami.instance_type)
VPC_CIDR=$(cat ${OUTFILE}|jq -r .resource_config.vpc_info.vpc_cidr)
NSXT=$(cat ${OUTFILE}|jq -r .resource_config.nsxt)
EXPIRATION_DATE=$(cat ${OUTFILE}|jq -r .expiration_date)
POP_IPADDRESS=$(cat ${OUTFILE}|jq -r .resource_config.agent.internal_ip)
VPC_VGW=$(cat ${OUTFILE}|jq -r .resource_config.vpc_info.vgw_id)

cat << EOF
SDDCName: ${SDDC_NAME}
SDDC_ID: ${SDDC_ID}
Version: ${SDDC_VERSION}
CreateDate: ${CREATE_DATE}
User_Name: ${USER_NAME}
ExpirationDate: ${EXPIRATION_DATE}
DeploymentType: ${DEPLOYMENT_TYPE}
Region: ${REGION}
AvaiabilityZone: ${AVAILABILITY_ZONE}
InstanceType: ${INSTANCE_TYPE}
VpcCIDR: ${VPC_CIDR}
PoPIP: ${POP_IPADDRESS}
NSXT: ${NSXT}
VPC_VGW: ${VPC_VGW}
EOF
ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo ${ELAPSED}