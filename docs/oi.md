# scripts/oi.sh

This script is a wrapper around the openshfit-install binary that sets/adds functionality useful for a developer.

# Usage

oi.sh [options]... [openshift-install parameters]

Exampe: oi.sh --install-config ~/oi/gcp/xpn-install-config.yaml create cluster

Note: OPENSHIFT\_INSTALL\_RELEASE\_IMAGE\_OVERRIDE will set to use 'ocp' releases instead of 'origin' whenever the binary is not an official release, such as nightly builds and when compiled from source. This is determined by the release image existing in the ci registry per the output of openshift-install version.

# Options

- **-h --help** display help for this script.
- **-d --dir** (default: 'assets') the path to the directory to use for this installation. The selected path is used by this script in addition to being passed to the openshift-install binary when invoked.
- **-i --install-config** (default: '') the path to an existing install-config.yaml. This enables you to create one or more install-config templates and select which one you use for this installation. It is recommended to store these templates in the ~/oi directory or a subdirectory thereof. If specified, it will be copied into the specified directory prior invoking the openshift-install binary. If ~/oi/pull-secret.json exists, then it will be automatically added/updated to the resulting install-config.yaml file. If ~/.ssh/oi.pub exists, then it will be automatically added/updated to the resulting install-config.yaml file. Each template needs only the json key-pairs that make this cluster unique compared to the openshift-install defaults. Leaving this empty will invoke the installer without an existing install-config.yaml at which point it will prompt for the survey questions as normal.
- **-l --log-level** (default: 'debug') the log level for the openshift-install binary to use (e.g. debug | info | warn | error)
- **-r --release** (default: '') the OpenShift release to install. This value is only used when the OPENSHIFT\_INSTALL\_RELEASE\_IMAGE\_OVERRIDE is invoked per the note above. As a result, officially released versions of the installer binary will always ignore this parameter and install exactly the version they were compiled for. Otherwise, the default behavior is to use the version specified by the openshift-install binary per the output of openshift-install version. If specified, it will update OPENSHIFT\_INSTALL\_RELEASE\_IMAGE\_OVERRIDE use the targeted release. Keep in mind, there are few situations where this will result in a functioning cluster. For example, installing a v4.10 cluster using an openshift-install binary compiled form the release-4.9 branch is not likely to succeed. However, installing a v.4.NEXT cluster using a binary compiled from the master branch may sometimes be necessary.
- **-t --token** (default: '') adds/updates the credentials for api.ci.openshift.org in the ${HOME}/pull-secret.txt file when specified. This update happens before the pull-secret.txt is added/updated in the install-config template. The value should be the hash provided after navigating to the `copy login command` from the [CI cluster](https://console-openshift-console.apps.ci.l2s4.p1.openshiftapps.com)

# Prerequisites

- **PyYAML** The python YAML module is required to to modify the install-config.yaml templates.
- **~/oi/pull-secret.json** This file should contain the concents of your pull secret. If this file exists, then the install config will use the contents to populate the pullSecret field.
- **~/.ssh/oi** This file should contain the private ssh key, used to connect to nodes in your cluster.
- **~/.ssh/oi.pub** This file should contain the public ssh key used to connect to nodes in your cluster. If this file exists, then the install config will use the contents to populate the sshKey field.

# Environment Variables

- **ASSETDIR** The directory to use as an asset directory as per the --dir option above.
- **INSTALLCONFIG** The location of the install config template as per the --install-config option above.
- **LOGLEVEL** The log level to use as per the --log-level option above.
- **PULLSECRET** The location of the pull secret to use when generating an install config from a template.
- **RELEASE** The release to use as per the --release option above.
- **SSHKEYPUB** The location of the public ssh key to use when generating an install config from a template.
- **TOKEN** The token to use when updating the pull secret as per the --token option above.
