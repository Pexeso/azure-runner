#!/bin/bash
set -e

type az gh > /dev/null

template_setup() {
    template_file="setup.sh"
    sed_script="s|{{token}}|${RUNNER_TOKEN}|g"
    sed_script="${sed_script};s|{{repo}}|${GITHUB_REPO}|g"
    sed_script="${sed_script};s|{{label}}|${LABEL}|g"
    sed "${sed_script}" "${template_file}.template" > "${template_file}"
}

if [[ -z "${GITHUB_REPO}" ]];then
    >&2 echo "env var GITHUB_REPO not defined" 
    exit 1
fi

if [[ -z "${GH_TOKEN}" ]];then
    >&2 echo "env var GH_TOKEN not defined" 
    exit 1
fi

if [[ -z "${RUN_ID}" ]];then
    >&2 echo "env var RUN_ID not defined" 
    exit 1
fi

RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-ghrunner}${RUN_ID}"
: "${LOCATION:=northeurope}"
: "${VM_IMAGE:=Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest}"
: "${VM_SIZE:=Standard_B1s}"
VM_NAME="${RESOURCE_GROUP_NAME}vm"
VM_USERNAME='vm'


test -z "${UNIQ_LABEL}" && UNIQ_LABEL=$(shuf -er -n8  {a..z} | paste -sd "")
LABEL="azure,${UNIQ_LABEL}"
RUNNER_TOKEN=$(gh api -XPOST --jq '.token' "repos/${GITHUB_REPO}/actions/runners/registration-token")

if [[ $1 = '--destroy' ]]; then
    # Set up destroy script
    template_setup
    VM_IP=$(az vm show --show-details --resource-group "${RESOURCE_GROUP_NAME}" --name "${VM_NAME}" --query publicIps --output tsv)
    ssh-keyscan "${VM_IP}" >> "${HOME}/.ssh/known_hosts" 2> /dev/null
    ssh "${VM_USERNAME}@${VM_IP}" 'bash -s -- --destroy' < setup.sh
    ssh-keygen -R "${VM_IP}"
    # Delete the resource group
    az group delete --name "${RESOURCE_GROUP_NAME}" --no-wait --yes --output none
    exit 0
fi

# Create the resource group
az group create --name "${RESOURCE_GROUP_NAME}" --location "${LOCATION}" --output none

# Set up setup script
template_setup

# Create the debian vm
az vm create \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --name "${VM_NAME}" \
    --image "${VM_IMAGE}" \
    --admin-username "${VM_USERNAME}" \
    --size "${VM_SIZE}" \
    --ssh-key-values "${HOME}/.ssh/id_rsa.pub" \
    --custom-data setup.sh \
    --public-ip-sku Standard \
    --vnet-name "${VNET_NAME}" \
    #--vnet-resource-group "${VNET_RG}" \
    --subnet "${SUBNET_NAME}" \
    --output none

VM_IP=$(az vm show --show-details --resource-group "${RESOURCE_GROUP_NAME}" --name "${VM_NAME}" --query publicIps --output tsv)

jq -n \
    --arg ip "$VM_IP" \
    --arg resource_group "$RESOURCE_GROUP_NAME" \
    --arg location "$LOCATION" \
    --arg vm_image "$VM_IMAGE" \
    --arg vm_size "$VM_SIZE" \
    --arg vm_name "$VM_NAME" \
    --arg vm_username "$VM_USERNAME" \
    --arg uniq_label "$UNIQ_LABEL" \
    '$ARGS.named'