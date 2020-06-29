#!/bin/sh

ASSETDIR="${1-assets}"
export KUBECONFIG=${ASSETDIR}/auth/kubeconfig

watch -n 10 "
  oc get clusterversion --no-headers \
  && oc get events -o json | jq -r \".items[] | select(.type != \\\"Normal\\\") | select(.reason != \\\"Rebooted\\\") | .lastTimestamp + \\\" \\\" + .type + \\\" \\\" + .reason + \\\": \\\" + .message\" | tail -n 5
  oc get nodes;
  oc get csr --no-headers --sort-by=\".metadata.creationTimestamp\"| grep \"Pending\";
  oc get clusteroperator | grep -v \"True        False         False\";
"
