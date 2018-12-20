cp /root/master-config.patch /root/openshift.local.clusterup/kube-apiserver
cp /root/master-config.patch /root/openshift.local.clusterup/openshift-apiserver
cp /root/master-config.patch /root/openshift.local.clusterup/openshift-controller-manager
cp openshift.local.clusterup/kube-apiserver/master-config.yaml{,.prepatch}
cp /root/openshift.local.clusterup/openshift-apiserver/master-config.yaml{,.prepatch}
cp /root/openshift.local.clusterup/openshift-controller-manager/master-config.yaml{,.prepatch}
oc ex config patch /root/openshift.local.clusterup/kube-apiserver/master-config.yaml.prepatch -p "$(cat /root/openshift.local.clusterup/kube-apiserver/master-config.patch)" > /root/openshift.local.clusterup/kube-apiserver/master-config.yaml
oc ex config patch /root/openshift.local.clusterup/openshift-apiserver/master-config.yaml.prepatch -p "$(cat /root/openshift.local.clusterup/openshift-apiserver/master-config.patch)" > /root/openshift.local.clusterup/openshift-apiserver/master-config.yaml
oc ex config patch /root/openshift.local.clusterup/openshift-controller-manager/master-config.yaml.prepatch -p "$(cat /root/openshift.local.clusterup/openshift-controller-manager/master-config.patch)" > /root/openshift.local.clusterup/openshift-controller-manager/master-config.yaml
