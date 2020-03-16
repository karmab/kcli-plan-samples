#!/usr/bin/env bash

#set -euo pipefail

export KUBECONFIG=${KUBECONFIG:-/root/ocp/auth/kubeconfig}
FEATURES_DIR="../../internal-baremetal-deploy/cnf-downstream"
export FEATURES="performance ptp sctp sriov dpdk"
git -c http.sslVerify=false clone https://code.engineering.redhat.com/gerrit/cnf-internal-deploy
cd cnf-internal-deploy/
git submodule update --init
sed -i "s/v4.4.0-.*/v4.4.0-48/"  internal-baremetal-deploy/cnf-downstream/performance/catalogsource.downstream.patch.yaml
FEATURES_ENVIRONMENT=../../internal-baremetal-deploy/cnf-downstream make -C cnf-features-deploy setup-test-cluster feature-deploy
