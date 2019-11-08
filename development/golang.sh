yum -y install git unzip wget jq
wget https://dl.google.com/go/go{{ go_version }}.linux-amd64.tar.gz
tar -C /usr/local -xzf go{{ go_version }}.linux-amd64.tar.gz
export GOPATH=/root/go
export PATH=$PATH:/usr/local/go/bin:${GOPATH}/bin:${GOPATH}/src/github/openshift/installer/bin
echo export GOPATH=/root/go >> ~/.bashrc
echo export PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin >> ~/.bashrc
mkdir -p ${GOPATH}/{bin,pkg,src}
