#!/bin/bash
#
# Based on:
# https://github.com/openshift/origin/blob/master/test/extended/README.md
# https://github.com/openshift/release/blob/master/ci-operator/step-registry/origin/e2e/test/origin-e2e-test-commands.sh
#
# Requirements:
# * ~/.gcp/osServiceAccount.json
# * assets/auth/kubeconfig
# * relevant versions of the following binaries (first up in $PATH)
#   * kubectl
#   * oc
#   * openshift-tests
set -uvo pipefail

ASSETDIR="${1-assets}"

TEST_SUITE="${TEST_SUITE-openshift/conformance/parallel}"
TEST_BINARY="${TEST_BINARY-openshift-tests}"

export GOOGLE_APPLICATION_CREDENTIALS="${HOME}/.gcp/osServiceAccount.json"

# Configure KUBECONFIG
if [[ ! -s "${ASSETDIR}/auth/kubeconfig" ]]; then
  echo "${ASSETDIR}/auth/kubeconfig empty or not found"
  exit 1
fi
export KUBECONFIG="${ASSETDIR}/auth/kubeconfig"

# Configure TEST_PRIVIDER based on platform
PLATFORM="$(oc get -o jsonpath='{.status.platform}' infrastructure cluster)"
case "${PLATFORM}" in
GCP)
  PROJECT_NAME="$(oc get -o jsonpath='{.status.platformStatus.gcp.projectID}' infrastructure cluster)"
  REGION="$(oc get -o jsonpath='{.status.platformStatus.gcp.region}' infrastructure cluster)"
  TEST_PROVIDER="{\"type\":\"gce\",\"region\":\"${REGION}\",\"multizone\": true,\"multimaster\":true,\"projectid\":\"${PROJECT_NAME}\"}"
  ;;
*)
  echo "Unsupported platform: ${PLATFORM}"
  exit 1
  ;;
esac

# Create directory to store test results
TEST_DIR="${ASSETDIR}/e2e/$(date -u +%Y%m%d%H%M%S)"
mkdir -p "${TEST_DIR}"

# Run test suite
"${TEST_BINARY}" run "${TEST_SUITE}" \
    --provider "${TEST_PROVIDER}" \
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
