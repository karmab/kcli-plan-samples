yum -y install libvirt-client libvirt-devel gcc-c++ git wget
wget https://dl.google.com/go/go{{ go_version }}.linux-amd64.tar.gz
tar -C /usr/local -xzf go{{ go_version }}.linux-amd64.tar.gz
export GOPATH=/root/go
export PATH=$PATH:/usr/local/go/bin:${GOPATH}/bin:${GOPATH}/src/github/openshift/installer/bin
echo export GOPATH=/root/go >> ~/.bashrc
echo export PATH=/root:\$PATH:/usr/local/go/bin:\$GOPATH/bin:\$GOPATH/src/github/openshift/installer/bin >> ~/.bashrc
echo alias go_installer=\"cd \$GOPATH/src/github.com/openshift/installer\">> ~/.bashrc
mkdir -p ${GOPATH}/{bin,pkg,src}
mkdir -p ${GOPATH}/src/github.com/openshift
cd ${GOPATH}/src/github.com/openshift
git clone https://github.com/{{ user_repo }}/installer.git
cd installer
git checkout {{ branch }}
export HOME=/root
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
export COMMIT_ID=$(git rev-parse HEAD)
{% if prs %}
{% for pr in prs %}
curl -L https://github.com/{{ user_repo }}/installer/pull/{{ pr }}.patch | git am
{% endfor %}
{% endif %}
TAGS='libvirt baremetal' hack/build.sh
mkdir /root/bin
cp bin/openshift-install /root/bin/openshift-baremetal-install
chmod u+x /root/bin/openshift-baremetal-install
