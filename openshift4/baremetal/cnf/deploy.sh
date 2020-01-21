
FEATURES_DIR="validation"
export FEATURES="performance ptp sctp sriov"

# TAGGING
MASTER_NODES=$(oc get nodes --selector='node-role.kubernetes.io/master' -o name)
WORKER_NODES=$(oc get nodes --selector='node-role.kubernetes.io/worker' -o name)
# tag first master for ptp
FIRST_MASTER=$(echo $MASTER_NODES | head -1)
oc label $FIRST_MASTER ptp/grandmaster=''
# tag workers for ptp
for node in $WORKER_NODES ; do 
  oc label $node ptp/slave=''
done

# tag all workers but last as worker-rt
sctpnode=$(echo "$WORKER_NODES" | tail  -1)
othernodes=$(echo "$WORKER_NODES" | grep -v $sctpnode)
for node in $othernodes ; do 
  oc label $node node-role.kubernetes.io/worker-rt=""
done
# tag last worker as sctp
oc label $sctpnode node-role.kubernetes.io/worker-sctp=""

# MCP
# create sctp machineconfigpool
oc create -f mcp_sctp.yml
# create worker-rt machineconfigpool
# oc create -f mcp_rt.yml

# DEPLOY
git clone https://github.com/openshift-kni/cnf-features-deploy
cd cnf-features-deploy
# create our own env structure
cp -r feature-configs/demo/ feature-configs/$FEATURES_DIR
sed -i "s@image:.*@image: registry-proxy.engineering.redhat.com/rh-osbs/performance-addon-operators-bundle-registry:v4.4.0@" validation/$FEATURES_DIR/performance/operator_catalogsource.patch.yaml
cp performance_profile.patch.yaml feature-configs/$FEATURES_DIR/performance
# launch deployment
FEATURES_ENVIRONMENT=$FEATURES_DIR make feature-deploy
