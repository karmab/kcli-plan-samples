CDI="{{ cdi_version }}"
if [ "$CDI" == 'latest' ] ; then
  CDI=`curl -s https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest| jq -r .tag_name`
fi
kubectl create clusterrolebinding cdi --clusterrole=edit --user=system:serviceaccount:kubevirt:default
kubectl create clusterrolebinding cdi-apiserver --clusterrole=cluster-admin --user=system:serviceaccount:kubevirt:cdi-apiserver
wget https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI}/cdi-controller.yaml
sed -i "s/kube-system/kubevirt/" cdi-controller.yaml
kubectl apply -f cdi-controller.yaml -n kubevirt
kubectl expose svc cdi-uploadproxy -n kubevirt
