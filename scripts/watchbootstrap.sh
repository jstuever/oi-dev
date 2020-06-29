#!/bin/bash

ASSETDIR="${1-assets}"

while true; do
  if [ -f ${ASSETDIR}/metadata.json ]; then
    if [ "$(jq '.aws' ${ASSETDIR}/metadata.json)" != "null" ]; then
      IP=$(jq '.resources[] | select(.module == "module.bootstrap") | select(.type == "aws_instance") | select(.name == "bootstrap") | .instances[0].attributes.public_ip' ${ASSETDIR}/terraform.tfstate | tr -d "\"")
    elif [ "$(jq '.gcp' ${ASSETDIR}/metadata.json)" != "null" ]; then
      IP=$(jq '.resources[] | select(.module == "module.bootstrap") | select(.type == "google_compute_address") | select(.name == "bootstrap") | .instances[0].attributes.address' ${ASSETDIR}/terraform.tfstate | tr -d "\"")
    else
      echo "No supported platforms found in ${ASSETDIR}/metadata.json"
    fi;
  else
    echo "${ASSETDIR}/metadata.json not found"
    IP="${1}"
  fi

  if [ -n "${IP}" ];
  then
    ssh -i ${OPT_PRIVATE_KEY:-'~/.ssh/openshift-dev.pem'} \
      -o ConnectTimeout=5 \
      -o StrictHostKeyChecking=no \
      -o PasswordAuthentication=no \
      -o UserKnownHostsFile=/dev/null \
      core@${IP} \
      'journalctl -b -f -u release-image.service -u bootkube.service'
  fi
  sleep 10
done;
