cd /root
git clone https://github.com/rook/rook
cd rook/cluster/examples/kubernetes/ceph
kubectl create namespace rook-ceph-system
kubectl create configmap csi-cephfs-config -n rook-ceph-system --from-file=csi/template/cephfs
kubectl create configmap csi-rbd-config -n rook-ceph-system --from-file=csi/template/rbd
kubectl apply -f csi/rbac/rbd
kubectl apply -f csi/rbac/cephfs/
sed -i 's@rook/ceph@karmab/ceph@' operator-with-csi.yaml
kubectl create -f operator-with-csi.yaml
sleep 180 
sed -i "s/useAllDevices: .*/useAllDevices: true/" cluster.yaml
kubectl create -f cluster.yaml
kubectl create -f toolbox.yaml
kubectl create -f /root/rook_pool.yml
sleep 240
KEY=$(pod=$(kubectl get pod  -n rook-ceph-system -l app=rook-ceph-operator  -o jsonpath="{.items[0].metadata.name}"); kubectl exec -n rook-ceph-system ${pod} -- bash -c "ceph auth get-key client.admin -c /var/lib/rook/rook-ceph/rook-ceph.config | base64")
sed -i "s/KEY/$KEY/" /root/rook_secret.yml
kubectl create -f /root/rook_secret.yml
kubectl create -f /root/rook_sc.yml
