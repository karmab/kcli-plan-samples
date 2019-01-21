VERSION="{{ cdi_version }}"
if [ "$VERSION" == "latest" ] ; then
VERSION=`curl -s https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest | jq -r .tag_name`
fi
oc new-project cdi
oc adm policy add-scc-to-user privileged system:serviceaccount:cdi:default
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:cdi:cdi-apiserver
wget -P /root/ https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-controller.yaml
oc create -f /root/cdi-controller.yaml
oc expose svc cdi-uploadproxy -n golden
