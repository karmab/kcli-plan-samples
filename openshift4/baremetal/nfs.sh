export KUBECONFIG=/root/ocp/auth/kubeconfig
export PRIMARY_IP=$(ip -o addr show baremetal | head -1 | awk '{print $4}' | cut -d'/' -f1)
yum -y install nfs-utils
mkdir /pv001
echo "/pv001 *(rw,no_root_squash)"  >>  /etc/exports
chcon -t svirt_sandbox_file_t /pv001
chmod 777 /pv001
exportfs -r
systemctl enable --now nfs-server
echo """apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
spec:
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteMany
  nfs:
    path: /pv001
    server: ${PRIMARY_IP}
  persistentVolumeReclaimPolicy: Recycle""" | oc create -f -
oc patch configs.imageregistry.operator.openshift.io cluster --type merge -p '{"spec":{"managementState":"Managed","storage":{"pvc":{}}}}'
