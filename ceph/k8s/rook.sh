kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/crds.yaml
kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/common.yaml
kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/operator.yaml
kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/cluster.yaml
# Toolbox
kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/toolbox.yaml
kubectl -n rook-ceph rollout status deploy/rook-ceph-tools
echo "alias c='kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash'" >> /root/.bashrc
source /root/.bashrc
# Report status (journalctl -t cloud.init)
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph -s