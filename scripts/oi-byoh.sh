#!/bin/sh
# Prerequisites:
# - the assets folder from a provisioned cluster
# - an ssh key, available in the cloud
# - openshift-ansible directory in PWD
#
set -o errexit -o pipefail -o nounset
ASSETDIR="assets"
INFRAID=""
PLATFORM=""
REGION=""

function usage () {
    echo "Usage: $(basename $0) [options]... command"
    echo "  Options:"
    echo "    -h, --help           help for $(basename $0)"
    echo "    -d, --dir            assets directory (default assets)"
    echo "  Commands:"
    echo "    bastion              creates the ssh bastion service in the cluster"
    echo "    create               creates the byoh machinesets"
    echo "    prepare              prepares the byoh machines with necessary repositories"
    echo "    scaleup              runs the openshift-ansible scaleup playbook"
    echo "    upgrade              runs the openshift-ansible upgrade playbook"
}

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
    *) SKIPPED+=("$1")
	shift
        ;;
esac done
set -- "${SKIPPED[@]}"

function bastion {
    echo "Setting up ssh bastion host..."
    export SSH_BASTION_NAMESPACE=test-ssh-bastion
    curl https://raw.githubusercontent.com/eparis/ssh-bastion/master/deploy/deploy.sh | bash -x
}

function create {
    if [ ! -f "playbooks/byoh-create-machines.yaml" ]; then
        echo "unable to create: playbooks/byoh-create-machines.yaml not found."
        exit
    fi

    time ansible-playbook -vv \
        --extra-vars "{\"asset_dir\":\"$(realpath ${ASSETDIR})\"}" \
        "playbooks/byoh-create-machines.yaml"
}

function prepare {
    if [ ! -f "playbooks/byoh-prepare.yaml" ]; then
        echo "unable to prepare: playbooks/byoh-prepare.yaml not found."
        exit
    fi

    time ansible-playbook -vv \
        -i "${ASSETDIR}/byoh/hosts" \
        --extra-vars "{\"asset_dir\":\"$(realpath ${ASSETDIR})\"}" \
        "playbooks/byoh-prepare.yaml"

}

function scaleup {
    if [ ! -d "./openshift-ansible" ]; then
        echo "unable to scaleup: openshift-ansible not found."
        exit
    fi

    time ansible-playbook -vv \
        -i "${ASSETDIR}/byoh/hosts" \
        "./openshift-ansible/playbooks/scaleup.yml"
}

function upgrade {
    if [ ! -d "./openshift-ansible" ]; then
        echo "unable to scaleup: openshift-ansible not found."
        exit
    fi

    time ansible-playbook -vv \
        -i "${ASSETDIR}/byoh/hosts" \
        "./openshift-ansible/playbooks/upgrade.yml"
}

export KUBECONFIG="${ASSETDIR}/auth/kubeconfig"
case "${1:-}" in
    'create')
        create
        ;;
    'bastion')
        bastion
        ;;
    'prepare')
        prepare
        ;;
    'scaleup')
        scaleup
        ;;
    'upgrade')
        upgrade
        ;;
    '')
        bastion
        create
	prepare
	scaleup
        ;;
    *)
        usage
        ;;
esac
