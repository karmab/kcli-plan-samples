cd /root
git clone https://github.com/rook/rook
cd rook/cluster/examples/kubernetes/ceph
sed -i '/ROOK_HOSTPATH_REQUIRES_PRIVILEGED/!b;n;c\          value: "true"' operator.yaml
oc create -f scc.yaml
oc create -f operator.yaml
sleep 180
sed -i "s/useAllDevices: .*/useAllDevices: true/" cluster.yaml
sed -i "s/    # port: 8443/    port: 8444/" cluster.yaml
oc create -f cluster.yaml
oc create -f toolbox.yaml
#kubectl create -f /root/rook_pool.yml
