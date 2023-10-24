#!/bin/bash
#
# Based on:
# https://github.com/openshift/origin/blob/master/test/extended/README.md
# https://github.com/openshift/release/blob/master/ci-operator/step-registry/origin/e2e/test/origin-e2e-test-commands.sh
#
# Requirements:
# * ~/.gcp/osServiceAccount.json
# * KUBECONFIG (default: assets/auth/kubeconfig)
# * relevant versions of the following binaries (first up in $PATH)
#   * kubectl
#   * oc
#   * openshift-tests
set -uvo pipefail

ASSETDIR="${1-assets}"

TEST_BINARY="${TEST_BINARY-openshift-tests}"
TEST_SUITE="${TEST_SUITE-openshift/conformance/parallel}"

export AZURE_AUTH_LOCATION="${HOME}/.azure/osServicePrincipal.json"
export GOOGLE_APPLICATION_CREDENTIALS="${HOME}/.gcp/osServiceAccount.json"
export KUBECONFIG=${KUBECONFIG-${ASSETDIR}/auth/kubeconfig}

# Configure KUBECONFIG
if [[ ! -s "${KUBECONFIG}" ]]; then
  echo "${KUBECONFIG} empty or not found"
  exit 1
fi

# Create directory to store test results
TEST_DIR="${ASSETDIR}/e2e/$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "${TEST_DIR}"

# Run test suite
"${TEST_BINARY}" run "${TEST_SUITE}" \
    -o "${TEST_DIR}/e2e.log" \
    --junit-dir "${TEST_DIR}"
ret="$?"

# Clean up /tmp after test suite
rm -rf /tmp/fixture-testdata-dir*

# Run must-gather if tests failed.
if [ $ret -ne 0 ]; then
  oc --insecure-skip-tls-verify adm must-gather --dest-dir "${TEST_DIR}/must-gather" > "${TEST_DIR}/must-gather.log"
  tar -czC "${TEST_DIR}/must-gather" -f "${TEST_DIR}/must-gather.tgz" .
  rm -rf "${TEST_DIR}/must-gather"
  exit "$ret"
fi
