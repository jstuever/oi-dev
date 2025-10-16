#!/bin/bash
if [ -z "${1}" ]; then
    echo "usage: $(basename $0) <IP>"
    exit
fi

IP=$1
shift

ssh -A -i ${OPT_PRIVATE_KEY:-'~/.ssh/oi'} \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -o PasswordAuthentication=no \
    -o UserKnownHostsFile=/dev/null \
    core@${IP} "$*"
