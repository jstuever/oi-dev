#!/bin/sh
set -o errexit -o pipefail -o nounset
ASSETDIR="assets"
INSTALLCONFIG=""
LOGLEVEL="DEBUG"
PULLSECRET="${HOME}/oi/pull-secret.json"
RELEASE=""
SSHKEYPUB="${HOME}/.ssh/oi.pub"

usage () {
    echo "Usage: $(basename $0) [OPTIONS]... [PARAMETERS]"
    echo "    -h, --help           help for $(basename $0)"
    echo "    -d, --dir            assets directory (default assets)"
    echo "    -i, --install-config path to existing install-config"
    echo "    -l, --log-level      log level (e.g. debug | info | warn | error) (default debug)"
    echo "    -r, --release        release image override version (e.g. 4.2, 4.3, ...)"
}

# Parse arguments
SKIPPED=()
while [[ $# -gt 0 ]]; do case $1 in
    -d=*|--dir=*)
        ASSETDIR="${1#*=}"
	shift
        ;;
    -d|--dir)
        ASSETDIR="$2"
        shift 2
        ;;
    -h|--help)
	usage
	exit $?
	;;
    -i|--install-config)
        INSTALLCONFIG="$2"
        shift 2
        ;;
    -l=*|--log-level=*)
        LOGLEVEL="${1#*=}"
	shift
        ;;
    -l|--log-level)
        LOGLEVEL="$2"
        shift 2
        ;;
    -r|--release)
        RELEASE="$2"
        shift 2
        ;;
    *)
        SKIPPED+=("$1")
	shift
        ;;
esac done
set -- "${SKIPPED[@]}"

# Create the asset dir if not exists.
if [ ! -d ${ASSETDIR} ]; then
    mkdir ${ASSETDIR}
fi

# Copy the install-confg if supplied, but only if a cluster not already exists.
if [ ! -f ${ASSETDIR}/install-config.yaml ] && [ ! -f ${ASSETDIR}/.openshift_install_state.json ]; then
    if [ ! -z "${INSTALLCONFIG}" ] && [ -f ${INSTALLCONFIG} ]; then
        cp ${INSTALLCONFIG} ${ASSETDIR}/install-config.yaml
        if [ -f ${PULLSECRET} ]; then
            python -c "import yaml; \
            path = '${ASSETDIR}/install-config.yaml'; \
            data = yaml.full_load(open(path)); \
            data['pullSecret'] = '$(<${PULLSECRET})'; \
            open(path, 'w').write(yaml.dump(data, default_flow_style=False));"
        fi
        if [ -f ${SSHKEYPUB} ]; then
            python -c "import yaml; \
            path = '${ASSETDIR}/install-config.yaml'; \
            data = yaml.full_load(open(path)); \
            data['sshKey'] = '$(<${SSHKEYPUB})'; \
            open(path, 'w').write(yaml.dump(data, default_flow_style=False));"
        fi
    fi
fi

# Override the release parameters on unreleased binaries
RELEASE_IMAGE="$(openshift-install version | grep '^release image ' | cut -d ' ' -f3)"
if [ "${RELEASE_IMAGE:0:41}" == "registry.ci.openshift.org/origin/release:" ]; then
    export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="registry.ci.openshift.org/ocp/release:${RELEASE:-${RELEASE_IMAGE:41}}"
    echo "OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE}"
fi

# Run openshift-install passing unused args
time openshift-install --dir=${ASSETDIR} --log-level=${LOGLEVEL} $@
