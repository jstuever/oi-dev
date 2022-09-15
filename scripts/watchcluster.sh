#!/bin/sh

# Determine if we are watching or executing.
if [[ "$1" == "--execute" ]]; then
  _EXECUTE=1
  shift
fi

# Input assetdir $1, or default to assets.
ASSETDIR="${1-${ASSETDIR-assets}}"
export KUBECONFIG=${ASSETDIR}/auth/kubeconfig

if [[ ${_EXECUTE-0} == 0 ]]; then
  # Watch while we re-run the script with --execute.
  watch -n 10 $0 --execute $*
  exit
fi

# Now we --execute
if [ -s ${KUBECONFIG} ]; then
  oc --request-timeout=2 get clusterversion --no-headers
  if [[ $? -ne 0 ]]; then
    exit
  fi
  oc --request-timeout=2 get events -o json |
    jq -r '.items[] | select(.type != "Normal") | select(.reason != "Rebooted") | .lastTimestamp + " " + .type + " " + .reason + ": " + .message' |
    tail -n 5
  oc --request-timeout=2 get nodes
  oc --request-timeout=2 get csr --no-headers --sort-by='.metadata.creationTimestamp' | grep 'Pending'
  oc --request-timeout=2 get clusteroperator | grep -v 'True        False         False'
else
  echo "${KUBECONFIG} not found."
fi
