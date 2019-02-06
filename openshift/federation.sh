FED="{{ federation_version }}"
yum -y install git bind-utils wget
echo function ocswitch { >> /root/.bashrc
echo oc config use-context \$1 >> /root/.bashrc
echo } >> /root/.bashrc
echo alias occontext=\"oc config get-contexts\" >> /root/.bashrc
echo alias oc1=\"oc --context=cluster1\" >> /root/.bashrc
echo alias oc2=\"oc --context=cluster2\" >> /root/.bashrc
echo alias oclogin=\"oc config use cluster2 \&\& oc login -u admin -p admin \; oc config use cluster1 \&\& oc login -u admin -p admin\" >> /root/.bashrc
{% if type == 'aws' or type == 'gcp' %}
export CLUSTER1={{ cluster }}1.{{ domain }}
export CLUSTER2={{ cluster }}2.{{ domain }}
{% else %}
export CLUSTER1=`dig +short {{ cluster }}1.{{ domain }}`.xip.io
export CLUSTER2=`dig +short {{ cluster }}2.{{ domain }}`.xip.io
{% endif %}
sleep 240
oc login --insecure-skip-tls-verify=true -u admin -p admin https://$CLUSTER2:8443
oc config rename-context `oc config current-context` cluster2
oc login --insecure-skip-tls-verify=true -u admin -p admin https://$CLUSTER1:8443
oc config rename-context `oc config current-context` cluster1
oc create ns federation-system
oc create ns kube-multicluster-public
oc create clusterrolebinding federation-admin --clusterrole=cluster-admin --serviceaccount="federation-system:default"
wget https://dl.google.com/go/go{{ go_version }}.linux-amd64.tar.gz
tar -C /usr/local -xzf go{{ go_version }}.linux-amd64.tar.gz
export GOPATH=/root/go
echo export GOPATH=/root/go >> /root/.bashrc
export PATH=${GOPATH}/src/github.com/kubernetes-sigs/federation-v2/bin:${PATH}:/usr/local/go/bin:${GOPATH}/bin
echo export PATH=\${GOPATH}/src/github.com/kubernetes-sigs/federation-v2/bin:\${PATH}:/usr/local/go/bin:\${GOPATH}/bin >> /root/.bashrc
mkdir -p ${GOPATH}/{bin,pkg,src}
mkdir -p ${GOPATH}/src/github.com/kubernetes-sigs
cd ${GOPATH}/src/github.com/kubernetes-sigs
git clone https://github.com/kubernetes-sigs/federation-v2.git
cd federation-v2
{% if federation_version != "canary" %} 
git checkout tags/$FED
{% endif %}
./scripts/download-binaries.sh
INSTALL_YAML="hack/install-latest.yaml"
IMAGE_NAME="quay.io/kubernetes-multicluster/federation-v2:{{ federation_version }}"
INSTALL_YAML="${INSTALL_YAML}" IMAGE_NAME="${IMAGE_NAME}" scripts/generate-install-yaml.sh
oc create -f ${INSTALL_YAML} -n federation-system
oc apply --validate=false -f vendor/k8s.io/cluster-registry/cluster-registry-crd.yaml
git stash
git checkout master
make kubefed2
for filename in ./config/federatedirectives/*.yaml; do kubefed2 enable -f "${filename}" --federation-namespace=federation-system; done
#curl -LOs https://github.com/kubernetes-sigs/federation-v2/releases/download/$FED/kubefed2.tar.gz
#tar xzf kubefed2.tar.gz -C /usr/local/bin
#rm -f kubefed2.tar.gz
kubefed2 join cluster1 --host-cluster-context cluster1 --add-to-registry --v=2
kubefed2 join cluster2 --host-cluster-context cluster1 --add-to-registry --v=2
