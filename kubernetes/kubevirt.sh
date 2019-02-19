KUBEVIRT="{{ kubevirt_version }}"
if [ "$KUBEVIRT" == 'latest' ] ; then
    KUBEVIRT=`curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest| jq -r .tag_name`
fi
yum -y install xorg-x11-xauth virt-viewer wget
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
setenforce 0
kubectl config set-context `kubectl config current-context` --namespace=kube-system
if [ "$KUBEVIRT" == "master" ] || [ "$KUBEVIRT" -eq "$KUBEVIRT" ] ; then
  yum -y install git make
  cd /root
  git clone https://github.com/kubevirt/kubevirt
  cd kubevirt
  export KUBEVIRT_PROVIDER=external
  if [ "$KUBEVIRT" -eq "$KUBEVIRT" ] ; then
    git fetch origin refs/pull/$KUBEVIRT/head:pull_$KUBEVIRT
    git checkout pull_$KUBEVIRT
  fi
  source hack/config-default.sh
  sed -i "s/\$docker_prefix/kubevirt/" hack/*sh
  sed -i "s/\${docker_prefix}/kubevirt/" hack/*sh
  make cluster-up
  make docker
  make manifests
  sed -i "s/latest/devel/" _out/manifests/release/kubevirt.yaml
  kubectl create -f _out/manifests/release/kubevirt.yaml
else
  wget https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT}/kubevirt-operator.yaml
  wget https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT}/kubevirt-cr.yaml
  kubectl create -f kubevirt-operator.yaml
  wget https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT}/virtctl-${KUBEVIRT}-linux-amd64
  mv virtctl-${KUBEVIRT}-linux-amd64 /usr/bin/virtctl
  chmod u+x /usr/bin/virtctl
  kubectl create -f kubevirt-cr.yaml
fi
kubectl config set-context `kubectl config current-context` --namespace=default
kubectl create configmap kubevirt-config --from-literal feature-gates=LiveMigration,DataVolumes -n kubevirt
