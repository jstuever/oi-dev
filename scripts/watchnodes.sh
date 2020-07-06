#!/bin/sh

# Determine if we are watching or executing.
if [[ "$1" == "--execute" ]]; then
  _EXECUTE=1
  shift
fi

# Input assetdir $1, or default to assets.
ASSETDIR="${1-assets}"

if [[ ${_EXECUTE-0} == 0 ]]; then
  # Watch while we re-run the script with --execute.
  watch -n 10 $0 --execute $*
  exit
fi

# Now we --execute
if [ -s ${ASSETDIR}/metadata.json ]; then
  if [ "$(jq '.gcp' ${ASSETDIR}/metadata.json)" != "null" ]; then
    gcloud compute instances list --filter="name~$(jq -r .infraID ${ASSETDIR}/metadata.json)"
  else
    echo "No supported platforms found in ${ASSETDIR}/metadata.json"
  fi
else
  echo "${ASSETDIR}/metadata.json not found"
fi
