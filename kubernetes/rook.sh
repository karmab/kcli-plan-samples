which oc && OC="1"
cd /root
git clone https://github.com/rook/rook
cd rook/cluster/examples/kubernetes/ceph
[ -z "$OC" ] && sed -i '/ROOK_HOSTPATH_REQUIRES_PRIVILEGED/!b;n;c\          value: "true"' operator-with-csi.yaml
[ -z "$OC" ] && oc adm policy add-scc-to-user privileged -z rook-csi-rbd-provisioner-sa -n rook-ceph-system
[ -z "$OC" ] && oc adm policy add-scc-to-user privileged -z rook-csi-rbd-attacher-sa -n rook-ceph-system
[ -z "$OC" ] && oc adm policy add-scc-to-user privileged -z csi-rook-csi-rbd-plugin-sa -n rook-ceph-system
[ -z "$OC" ] && oc adm policy add-scc-to-user privileged -z rook-csi-cephfs-plugin-sa -n rook-ceph-system
[ -z "$OC" ] && oc adm policy add-scc-to-user privileged -z rook-csi-cephfs-provisioner-sa -n rook-ceph-system
[ -z "$OC" ] && kubectl create -f scc.yaml
kubectl create namespace rook-ceph-system
kubectl create configmap csi-cephfs-config -n rook-ceph-system --from-file=csi/template/cephfs
kubectl create configmap csi-rbd-config -n rook-ceph-system --from-file=csi/template/rbd
kubectl apply -f csi/rbac/rbd
kubectl apply -f csi/rbac/cephfs/
kubectl create -f operator-with-csi.yaml
sleep 180 
sed -i "s/useAllDevices: .*/useAllDevices: true/" cluster.yaml
[ -z "$OC" ] && sed -i "s/    # port: 8443/      port: 8444/" cluster.yaml
kubectl create -f cluster.yaml
kubectl create -f toolbox.yaml
kubectl create -f /root/rook_pool.yml
KEY=$(pod=$(kubectl get pod  -n rook-ceph-system -l app=rook-ceph-operator  -o jsonpath="{.items[0].metadata.name}"); kubectl exec -ti -n rook-ceph-system ${pod} -- bash -c "ceph auth get-key client.admin -c /var/lib/rook/rook-ceph/rook-ceph.config | base64")
sed -i "s/KEY/$KEY/" /root/rook_secret.yml
kubectl create -f - /root/rook_secret.yml
kubectl create -f - /root/rook_sc.yml
