#!/usr/bin/env bash

#set -euo pipefail

target="integration-u08"
git clone https://github.com/openshift-kni/cnf-features-deploy.git
cd cnf-features-deploy
FEATURES_ENVIRONMENT=$target FEATURES="performance ptp sctp dpdk sriov" make setup-test-cluster feature-deploy
