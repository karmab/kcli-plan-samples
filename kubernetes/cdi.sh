CDI="{{ cdi_version }}"
if [ "$CDI" == 'latest' ] ; then
  CDI=`curl -s https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest| jq -r .tag_name`
fi
wget https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI}/cdi-operator.yaml
wget https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI}/cdi-operator-cr.yaml
kubectl create -f cdi-operator.yaml
kubectl create -f cdi-operator-cr.yaml
kubectl expose svc cdi-uploadproxy -n cdi
