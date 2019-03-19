echo 192.168.126.11 {{ cluster }}-api.{{ domain }} api.{{ cluster }}.{{ domain }} >> /etc/hosts
yum -y install libvirt-client libvirt-devel gcc-c++ git unzip wget jq compat-openssl10
ssh-keyscan -H 192.168.122.1 >> ~/.ssh/known_hosts
build=`curl -s https://releases-rhcos.svc.ci.openshift.org/storage/releases/maipo/builds.json | jq -r '.builds[0]'`
image=`curl -s https://releases-rhcos.svc.ci.openshift.org/storage/releases/maipo/$build/meta.json | jq -r '.images["qemu"].path'`
url="https://releases-rhcos.svc.ci.openshift.org/storage/releases/maipo/$build/$image"
curl --compressed -L -o /root/rhcos-qemu.qcow2 $url
wget https://dl.google.com/go/go{{ go_version }}.linux-amd64.tar.gz
tar -C /usr/local -xzf go{{ go_version }}.linux-amd64.tar.gz
export GOPATH=/root/go
export PATH=$PATH:/usr/local/go/bin:${GOPATH}/bin:${GOPATH}/src/github/openshift/installer/bin
export KUBECONFIG=$HOME/clusters/nested/auth/kubeconfig
echo export GOPATH=/root/go >> ~/.bashrc
echo export PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin:\$GOPATH/src/github/openshift/installer/bin >> ~/.bashrc
echo export KUBECONFIG=\$GOPATH/src/github.com/openshift/installer/kubeconfig >> ~/.bashrc
echo alias go_installer=\"cd \$GOPATH/src/github.com/openshift/installer\">> ~/.bashrc
echo alias install=\"cd \$GOPATH/src/github.com/openshift/installer && bin/openshift-install create cluster --log-level=debug\">> ~/.bashrc
mkdir -p ${GOPATH}/{bin,pkg,src}
mkdir -p ${GOPATH}/src/github.com/openshift
cd ${GOPATH}/src/github.com/openshift
curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
git clone https://github.com/openshift/installer.git
cd installer
sed -i -e 's/memory = "2048"/memory = "{{ bootstrap_memory }}"/g' data/data/libvirt/bootstrap/main.tf
sed -i -e 's/default     = "6144"/default     = {{ master_memory }}/g' data/data/libvirt/variables-libvirt.tf
sed -i -e "s/DomainMemory: .*/DomainMemory: {{ node_memory }}/g" pkg/asset/machines/libvirt/machines.go
sed -i -e "s/apiTimeout := 30 \* time.Minute/apiTimeout := 60 \* time.Minute/g" -e "s/eventTimeout := 30 \* time.Minute/eventTimeout := 60 \* time.Minute/g" -e "s/timeout := 30 \* time.Minute/timeout := 60 \* time.Minute/g" -e "s/consoleRouteTimeout := 10 \* time.Minute/consoleRouteTimeout := 20 \* time.Minute/g" cmd/openshift-install/create.go
dep ensure
hack/get-terraform.sh
TAGS=libvirt hack/build.sh
GOBIN=~/.terraform.d/plugins go get -u github.com/dmacvicar/terraform-provider-libvirt
PUBKEY=`cat ~/.ssh/authorized_keys`
PULLSECRET=`cat ~/openshift_pull.json`
sed -i "s%PUBKEY%$PUBKEY%" /root/install-config.yaml
sed -i "s%PULLSECRET%$PULLSECRET%" /root/install-config.yaml
cp bin/openshift-install /usr/bin
chmod +x /usr/bin/openshift-install
mkdir /root/assets
cp /root/install-config.yaml /root/assets
# openshift-install create cluster --dir=/root/assets --log-level=debug
