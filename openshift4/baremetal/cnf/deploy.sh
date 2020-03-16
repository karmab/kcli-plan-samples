#!/usr/bin/env bash

#set -euo pipefail

#!/usr/bin/env bash
#set -euo pipefail
export KUBECONFIG=${KUBECONFIG:-/root/ocp/auth/kubeconfig}
FEATURES_DIR="../../internal-baremetal-deploy/cnf-downstream"
export FEATURES="performance ptp sctp sriov dpdk"
git -c http.sslVerify=false clone https://code.engineering.redhat.com/gerrit/cnf-internal-deploy
cd cnf-internal-deploy/
git submodule update --init
sed -i "s/v4.4.0-.*/v4.4.0-48/"  cnf-internal-deploy/internal-baremetal-deploy/cnf-downstream/performance/catalogsource.downstream.patch.yaml
cp -r cnf-internal-deploy/internal-baremetal-deploy/cnf-downstream/sctp cnf-internal-deploy/internal-baremetal-deploy/cnf-downstream/ptp
sed -i s/sctp/ptp cnf-internal-deploy/internal-baremetal-deploy/cnf-downstream/ptp/kustomization.yaml

FEATURES_ENVIRONMENT=../../internal-baremetal-deploy/cnf-downstream make -C cnf-features-deploy setup-test-cluster feature-deploy

#target="integration-u08"
#git clone https://github.com/openshift-kni/cnf-features-deploy.git
#git clone https://code.engineering.redhat.com/gerrit/cnf-internal-deploy.git
#cd cnf-features-deploy
#FEATURES_ENVIRONMENT=$target FEATURES="performance ptp sctp dpdk sriov" make setup-test-cluster feature-deploy
