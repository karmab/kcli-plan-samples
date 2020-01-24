#!/usr/bin/env bash

set -euo pipefail

export KUBECONFIG=${KUBECONFIG:-/root/ocp/auth/kubeconfig}
FEATURES_DIR="validation"
export FEATURES="{{ cnf_features | join(' ') }}"

# TAGGING
master_nodes=$(oc get nodes --selector='node-role.kubernetes.io/master' -o name)
worker_nodes=$(oc get nodes --selector='node-role.kubernetes.io/worker' -o name)
num_workers=$(echo $worker_nodes | wc -l)
# tag first master for ptp
first_master=$(echo $master_nodes | head -1)
oc label $first_master ptp/grandmaster=''
# tag workers for ptp
for node in $worker_nodes ; do 
  oc label $node ptp/slave=''
done

# tag all workers but last as worker-rt
sctp_node=$(echo "$worker_nodes" | tail  -1)
other_nodes=$(echo "$worker_nodes" | grep -v $sctp_node)
for node in $other_nodes ; do 
  oc label $node node-role.kubernetes.io/worker-rt=""
done
# tag last worker as sctp
oc label $sctp_node node-role.kubernetes.io/worker-sctp=""

# MCP
# create sctp machineconfigpool
oc create -f mcp_sctp.yml
# create worker-rt machineconfigpool
oc create -f mcp_rt.yml

# DEPLOY
git clone https://github.com/openshift-kni/cnf-features-deploy
cd cnf-features-deploy
# create our own env structure
cp -r feature-configs/demo feature-configs/$FEATURES_DIR
sed -i "s@image:.*@image: registry-proxy.engineering.redhat.com/rh-osbs/performance-addon-operators-bundle-registry:v4.4.0@" feature-configs/$FEATURES_DIR/performance/operator_catalogsource.patch.yaml
rm -rf feature-configs/$FEATURES_DIR/performance/performance_profile.patch.yaml
cp ../performance_profile.patch.yaml feature-configs/$FEATURES_DIR/performance
FEATURES_ENVIRONMENT=$FEATURES_DIR make feature-deploy
