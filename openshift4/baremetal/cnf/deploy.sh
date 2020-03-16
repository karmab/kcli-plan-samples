#!/usr/bin/env bash

#set -euo pipefail

yum -y install git
target="integration-u08"
#git clone https://github.com/openshift-kni/cnf-features-deploy.git
git clone https://code.engineering.redhat.com/gerrit/cnf-internal-deploy.git
cd cnf-features-deploy
#FEATURES_ENVIRONMENT=$target FEATURES="performance ptp sctp dpdk sriov" make setup-test-cluster feature-deploy
