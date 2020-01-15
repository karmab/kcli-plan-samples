
FEATURES_DIR="validation"
# tag nodes
WORKER_NODES=$(oc get nodes --selector='node-role.kubernetes.io/worker' -o name)
node=$(echo "$WORKER_NODES" | wc -l)
sctpnode=$(echo "$WORKER_NODES" | head -1)
oc label $sctpnode node-role.kubernetes.io/worker-sctp=""
othernodes=$(echo "$WORKER_NODES" | grep -v $sctpnode)
for node in $othernodes ; do 
  oc label $node node-role.kubernetes.io/worker-rt=""
done
# create mcp sctp
oc create -f mcp_sctp.yml
git clone https://github.com/openshift-kni/cnf-features-deploy
cd cnf-features-deploy
# create our own env structure
cp -r feature-configs/demo/ feature-configs/$FEATURES_DIR
sed -i "s@image:.*@image: registry-proxy.engineering.redhat.com/rh-osbs/performance-addon-operators-bundle-registry:v4.4.0@" validation/$FEATURES_DIR/performance/operator_catalogsource.patch.yaml
cp performance_profile.patch.yaml feature-configs/$FEATURES_DIR/performance
# launch deployment
FEATURES_ENVIRONMENT=$FEATURES_DIR make feature-deploy
