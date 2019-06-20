CDI="{{ cdi_version }}"
if [ "$CDI" == 'latest' ] ; then
  COMPONENT="kubevirt/containerized-data-importer"
  CDI=$(curl -s https://api.github.com/repos/$COMPONENT/releases|grep tag_name|sort -V | tail -1 | awk -F':' '{print $2}' | sed 's/,//' | xargs)
fi
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI}/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI}/cdi-operator-cr.yaml
kubectl expose svc cdi-uploadproxy -n cdi
