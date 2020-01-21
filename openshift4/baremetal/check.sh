export KUBECONFIG=/root/ocp/auth/kubeconfig
echo "Cluster info:"
oc get clusterversion
echo "Nodes info:"
oc get nodes
echo "Pods info:"
oc get pod -A
