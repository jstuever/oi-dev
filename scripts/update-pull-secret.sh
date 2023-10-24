#!/bin/sh
PULLSECRET="${HOME}/oi/pull-secret.json"
SERVER=""
TOKEN=""

usage () {
    echo "Usage: $(basename $0) --token token --server server [--file pullsecret]"
    echo "    -h, --help    help for $(basename $0)"
    echo "    -f, --file    location of pull secret (defaults to ${PULLSECRETFILE})"
    echo "    -s, --server  server to request authenticion from"
    echo "    -t, --token   use this token to replace auth for specified server"
    echo
    echo "TOKEN: https://console-openshift-console.apps.ci.l2s4.p1.openshiftapps.com"
}

if [ $# -eq 0 ]; then usage; exit 1; fi

# Parse arguments
SKIPPED=()
while [[ $# -gt 0 ]]; do case $1 in
    -h|--help)
	usage
	exit $?
	;;
    -f=*|--file=*)
        PULLSECRET="${1#*=}"
	shift
        ;;
    -f|--file)
        PULLSECRET="$2"
        shift 2
        ;;
    -s=*|--server=*)
        SERVER="${1#*=}"
	shift
        ;;
    -s|--server)
        SERVER="$2"
        shift 2
        ;;
    -t=*|--token=*)
        TOKEN="${1#*=}"
	shift
        ;;
    -t|--token)
        TOKEN="$2"
        shift 2
        ;;
    *)
        SKIPPED+=("$1")
	shift
        ;;
esac done
set -- "${SKIPPED[@]}"

if [ -z "${SERVER}" ]; then
    echo "Error: no server specified"
    usage
    exit 1
fi

if [ ! -f "${PULLSECRET}" ]; then
    echo "Error: pull-secret not found: ${PULLSECRET}"
    exit 2
fi

if [ -z "${TOKEN}" ]; then
    echo "Error: no token specified"
    usage
    exit 1
fi

oc login --server="${SERVER}" --token="${TOKEN}" >> /dev/null
oc registry login --to /tmp/secret.json
echo $(jq -sc '.[0] * .[1]' ${PULLSECRET} /tmp/secret.json) > ${PULLSECRET}
rm /tmp/secret.json
