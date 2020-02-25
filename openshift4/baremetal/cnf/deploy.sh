#!/usr/bin/env bash

#set -euo pipefail

target="u08"
export HOME=/root
git config --global http.sslVerify false
git clone https://gitlab.cee.redhat.com/sysdeseng/cnf-integration.git
git clone https://github.com/openshift-kni/cnf-features-deploy.git
cd cnf-features-deploy
FEATURES_ENVIRONMENT=../../cnf-integration/cnf-kustomize/$target FEATURES="performance ptp sctp dpdk sriov" make setup-test-cluster feature-deploy
