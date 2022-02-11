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
SSHKEY="${HOME}/.ssh/oi"
SSHKEYPUB="${SSHKEY}.pub"

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
    echo "    ssh <host>           ssh to a host via the bastion host"
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
    if [ -f "${ASSETDIR}/byoh/bastion" ]; then
        echo "Using existing bastion: ${ASSETDIR}/byoh/bastion"
        exit;
    fi
    if [ ! -f "${KUBECONFIG}" ]; then
        echo "unable to create bastion: ${KUBECONFIG} not found."
        exit;
    fi
    bastion="$(oc get service -n test-ssh-bastion ssh-bastion -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo '')"
    if [ -z "${bastion}" ]; then
        echo "Setting up ssh bastion host..."
        export SSH_BASTION_NAMESPACE=test-ssh-bastion
        curl https://raw.githubusercontent.com/eparis/ssh-bastion/master/deploy/deploy.sh | bash -x
        bastion="$(oc get service -n test-ssh-bastion ssh-bastion -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo '')"
    fi
    if [ -z "${bastion}" ]; then
        echo "unable to create bastion."
        exit;
    fi
    if [ ! -z "${ASSETDIR}/byoh" ]; then
        mkdir -p "${ASSETDIR}/byoh"
    fi
    echo "Creating bastion file: ${ASSETDIR}/byoh/bastion"
    echo "${bastion}" >> "${ASSETDIR}/byoh/bastion"
}

function bastion_ssh {
    if [ ! -f "${ASSETDIR}/byoh/bastion" ]; then
        echo "Unable to ssh: ${ASSETDIR}/byoh/bastion not found."
        exit;
    fi
    echo "$@"
    ssh -o IdentityFile=${SSHKEY} -o StrictHostKeyChecking=no -o \
        ProxyCommand="ssh -o IdentityFile=${SSHKEY} -o ConnectTimeout=30 \
            -o ConnectionAttempts=100 -o StrictHostKeyChecking=no -W %h:%p -q \
            core@$(<${ASSETDIR}/byoh/bastion)" \
        $@
}

function create {
    if [ ! -f "playbooks/byoh-create-machines.yaml" ]; then
        echo "unable to create: playbooks/byoh-create-machines.yaml not found."
        exit
    fi

    if [ -z "${OI_SSH_BASTION:-}" ]; then
        if [ ! -f "${ASSETDIR}/byoh/bastion" ]; then
            echo "unable to create: ${ASSETDIR}/byoh/bastion not found."
            exit
        fi
    fi

    OI_SSH_BASTION="${OI_SSH_BASTION:-$(<${ASSETDIR}/byoh/bastion)}" \
    OI_SSH_PRIVATE_KEY="${OI_SSH_PRIVATE_KEY:-${SSHKEYPUB}}" \
    time ansible-playbook -vv \
        --extra-vars "{\"asset_dir\":\"$(realpath ${ASSETDIR})\"}" \
        "playbooks/byoh-create-machines.yaml"
}

function prepare {
    if [ ! -f "playbooks/byoh-prepare.yaml" ]; then
        echo "unable to prepare: playbooks/byoh-prepare.yaml not found."
        exit
    fi

    if [ ! -f "${ASSETDIR}/byoh/hosts" ]; then
        echo "unable to prepare: ${ASSETDIR}/byoh/hosts not found."
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

    if [ ! -f "${ASSETDIR}/byoh/hosts" ]; then
        echo "unable to scaleup: ${ASSETDIR}/byoh/hosts not found."
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

    if [ ! -f "${ASSETDIR}/byoh/hosts" ]; then
        echo "unable to upgrade: ${ASSETDIR}/byoh/hosts not found."
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
    'ssh')
        shift
        bastion_ssh $@
        ;;
    'upgrade')
        upgrade
        ;;
    '')
        if [ ! -f "${ASSETDIR}/byoh/bastion" ]; then
            bastion
        fi
        if [ ! -f "${ASSETDIR}/byoh/hosts" ]; then
            create
        fi
	prepare
	scaleup
        ;;
    *)
        usage
        ;;
esac
