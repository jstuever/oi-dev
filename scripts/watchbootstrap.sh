#!/bin/bash

# Determine if we are watching or executing.
if [[ "$1" == "--execute" ]]; then
  _EXECUTE=1
  shift
fi

# Input assetdir $1, or default to assets.
ASSETDIR="${1-assets}"

if [[ ${_EXECUTE-0} == 0 ]]; then
  # Watch while we re-run the script with --execute.
  while true; do
    $0 --execute $*
    sleep 10
  done
  exit
fi

# Now we --execute
if [ ! -s ${ASSETDIR}/metadata.json ]; then
  if [ -z "${1}" -o -d "${1}" ]; then
    echo "${ASSETDIR}/metadata.json not found"
    exit
  fi
  IP="${1}"
else
  INFRA_ID=$(jq -r '.infraID' ${ASSETDIR}/metadata.json)
  if [ "$(jq '.aws' ${ASSETDIR}/metadata.json)" != 'null' ]; then
    IP=$(jq '.resources[] | select(.module == "module.bootstrap") | select(.type == "aws_instance") | select(.name == "bootstrap") | .instances[0].attributes.public_ip' ${ASSETDIR}/terraform.tfstate | tr -d "\"")
  elif [ "$(jq '.gcp' ${ASSETDIR}/metadata.json)" != 'null' ]; then
    BOOTSTRAP_JSON=$(gcloud compute instances list --filter="name=${INFRA_ID}-bootstrap" --format json)
    echo ${BOOTSTRAP_JSON}
    if [ "${BOOTSTRAP_JSON}" == '[]' ]; then
      echo "Bootstrap instance not found: ${INFRA_ID}-bootstrap"
      exit
    fi
    IP=$(echo ${BOOTSTRAP_JSON} | jq -r '.[].networkInterfaces[0].accessConfigs[0].natIP')
    if [ "${IP}" == 'null' ]; then
      IP=$(echo ${BOOTSTRAP_JSON} | jq -r '.[].networkInterfaces[0].networkIP')
    fi
  elif [ "$(jq '.libvirt' ${ASSETDIR}/metadata.json)" != 'null' ]; then
    if [ -f "${ASSETDIR}/terraform.cluster.tfstate" ]; then
      IP=$(jq '.resources[] | select(.type == "libvirt_network_dns_host_template") | select(.name == "bootstrap") | .instances[0].attributes.ip' ${ASSETDIR}/terraform.cluster.tfstate | tr -d "\"")
    else
      IP=$(jq '.resources[] | select(.type == "libvirt_network_dns_host_template") | select(.name == "bootstrap") | .instances[0].attributes.ip' ${ASSETDIR}/terraform.tfstate | tr -d "\"")
    fi
  else
    echo "No supported platforms found in ${ASSETDIR}/metadata.json"
    exit
  fi
fi

if [ ! -n "${IP}" ]; then
  echo "Unable to determine bootstrap IP."
  exit
fi

ssh -i ${OPT_PRIVATE_KEY:-'~/.ssh/openshift-dev.pem'} \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -o PasswordAuthentication=no \
    -o UserKnownHostsFile=/dev/null \
    core@${IP} \
    'journalctl -b -f -u release-image.service -u bootkube.service'
