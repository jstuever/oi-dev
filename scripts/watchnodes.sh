#!/bin/sh

ASSETDIR="${1-assets}"
export KUBECONFIG=${ASSETDIR}/auth/kubeconfig

watch -n 10 "
  if [ -s ${ASSETDIR}/metadata.json ]; then
    if [ \"$(jq '.gcp' ${ASSETDIR}/metadata.json)\" != \"null\" ]; then
      gcloud compute instances list --filter=\"name~$(jq -r .infraID ${ASSETDIR}/metadata.json)\"
    else
      echo \"No supported platforms found in ${ASSETDIR}/metadata.json\"
    fi
  else
    echo \"${ASSETDIR}/metadata.json not found\";
  fi
"
