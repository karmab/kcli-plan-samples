#!/usr/bin/env bash

#set -euo pipefail

export KUBECONFIG=${KUBECONFIG:-/root/ocp/auth/kubeconfig}
FEATURES_DIR="validation"
export FEATURES="{{ cnf_features | join(' ') }}"

# TAGGING
master_nodes=$(oc get nodes --selector='node-role.kubernetes.io/master' -o name)
worker_nodes=$(oc get nodes --selector='node-role.kubernetes.io/worker' -o name)
# tag first master for ptp
first_master=$(echo $master_nodes | head -1)
oc label $first_master ptp/grandmaster=''
# tag workers for ptp
for node in $worker_nodes ; do 
  oc label $node ptp/slave=''
done

# tag all workers as worker-cnf
for node in $worker_nodes ; do 
  oc label $node node-role.kubernetes.io/worker-cnf=""
done

# MCP
oc create -f mcp_cnf.yml

# DEPLOY
git clone https://github.com/openshift-kni/cnf-features-deploy
cd cnf-features-deploy
# create our own env structure
cp -r feature-configs/demo feature-configs/$FEATURES_DIR
sed -i "s@image:.*@image: registry-proxy.engineering.redhat.com/rh-osbs/performance-addon-operator-bundle-registry:v4.4.0@" feature-configs/$FEATURES_DIR/performance/operator_catalogsource.patch.yaml
rm -rf feature-configs/$FEATURES_DIR/performance/performance_profile.patch.yaml
cp ../performance_profile.patch.yaml feature-configs/$FEATURES_DIR/performance
FEATURES_ENVIRONMENT=$FEATURES_DIR make feature-deploy
