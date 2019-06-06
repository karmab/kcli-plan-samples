VERSION="{{ cdi_version }}"
if [ "$VERSION" == "latest" ] ; then
VERSION=`curl -s https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest | jq -r .tag_name`
fi
wget https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
wget https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator-cr.yaml
oc create -f cdi-operator.yaml
oc create -f cdi-operator-cr.yaml
oc expose svc cdi-uploadproxy -n cdi
