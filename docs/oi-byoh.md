# scripts/oi-byoh.sh

# Usage

oi-byoh.sh [options]... command

# Options

- **-h --help** display help for this script.
- **-d --dir** (default: 'assets') the path to the directory containing the openshift-install artifacts of an existing cluster. This script will attempt to identify the cluster and pre-populate the required variables based on the contents in the artifact directory. It will also store additional artifacts in the byoh subdirectory.

# Commands

If no commands are supplied, the default behavior is to run the following commands in sequence: bastion, create, prepare, scaleup.

- **bastion** creates an in-cluster bastion service for connecting to cluster hosts via ssh. This is a wrapper for [ssh-bastion](https://github.com/eparis/ssh-bastion).
- **create** creates byoh nodes using in-cluster machine sets. It uses included [playbooks](../playbooks) to instruct the cluster to deploy additional machines while overriding the targeted OS to be the desired flavor (RHEL7, RHEL8). As a result, these machines will automatically be cleaned up during an openshift-install destroy. In addition to creating the machines, it will query the cluster for these machines and create an ansible hosts file in the byoh subdirectory of the specified directory (assets/byoh/hosts). It requires that an in-cluster bastion service already exists per the bastion command.
- **prepare** configures the repositories and other aspects of the byoh hosts to enable the openshift-ansible playbooks to succeed. It requires the hosts file from the create command as well as a json file (~/oi/openshift-mirror.json) containing the .url, .username, and .password to an [openshift enterprise mirror](https://mirror2.openshift.com/enterprise).
- **scaleup** adds the hosts to the cluster by running the [openshift-ansible](http://www.github.com/openshift/openshift-ansible) scaleup playbook. It requries the hosts file from the create command as well as those hosts having the necessary repos to install the required packages. It expects the version approperiate playbook to exist in ${PWD}/openshift-ansible.
- **ssh** \<[user@]host\> ssh to the specified host using the bastion service.
- **upgrade** upgrades the hosts in the cluster by running the [openshift-ansible](http://www.github.com/openshift/openshift-ansible) upgrade playbook. It requries the hosts file from the create command as well as those hosts having the necessary repos to install the required packages. It expects the version approperiate playbook to exist in ${PWD}/openshift-ansible.

# Customization

The included [playbooks](../playbooks) include options to override some default behavior using environment variables. These variables are prefixed with `OI_` and can be identified by inspecting the relevant playbook.
- **OI_DISTRIBUTION_VERSION** (default: '8.5') The OS version to use when creating machines.
