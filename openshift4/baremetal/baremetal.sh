echo export KUBECONFIG=/root/ocp/auth/kubeconfig >> /root/.bashrc
echo export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=registry.svc.ci.openshift.org/ocp/release:{{ tag }} >> /root/.bashrc
echo export OS_CLOUD=metal3-bootstrap >> /root/.bashrc
yum -y install libvirt-libs ipmitool bridge-utils centos-release-openstack-train mkisofs tmux
yum -y install python2-openstackclient python2-ironicclient
echo -e "DEVICE=baremetal\nTYPE=Bridge\nONBOOT=yes\nNM_CONTROLLED=no\nBOOTPROTO=dhcp" > /etc/sysconfig/network-scripts/ifcfg-baremetal
echo -e "DEVICE=eth0\nTYPE=Ethernet\nONBOOT=yes\nNM_CONTROLLED=no\nBRIDGE=baremetal" > /etc/sysconfig/network-scripts/ifcfg-eth0
ifup eth0
ifup baremetal
echo -e "DEVICE=provisioning\nTYPE=Bridge\nONBOOT=yes\nNM_CONTROLLED=no\nBOOTPROTO=static\nIPADDR={{ provisioning_installer_ip }}\nPREFIX={{ provisioning_cidr }}" > /etc/sysconfig/network-scripts/ifcfg-provisioning
echo -e "DEVICE=eth1\nTYPE=Ethernet\nONBOOT=yes\nNM_CONTROLLED=no\nBRIDGE=provisioning" > /etc/sysconfig/network-scripts/ifcfg-eth1
ifup eth1
ifup provisioning
cd /root
curl --silent https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz > oc.tar.gz
tar zxf oc.tar.gz
rm -rf oc.tar.gz
export PATH=/root:$PATH
chmod +x oc

{% if not build %}
bash /root/get_installer.sh
{% endif %}

if [ -z "$COMMIT_ID" ] ; then
export COMMIT_ID=$(./openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')
fi
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
mv jq /usr/bin
chmod u+x /usr/bin/jq
wget -O yq https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64
mv yq /usr/bin
chmod u+x /usr/bin/yq
export RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.openstack.path | sed 's/"//g')
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')
envsubst < metal3-config.yaml.sample > metal3-config.yaml

PROVISIONING_IP=$(grep libvirtURI install-config.yaml | awk -F'/' '{ print $3 }' | awk -F'@' '{ print $2 }')
ssh-keyscan -H $PROVISIONING_IP >> ~/.ssh/known_hosts
echo -e "Host=*\nStrictHostKeyChecking=no\n" > .ssh/config
{% if run %}
run.sh
sed -i "s/metal3-bootstrap/metal3/" /root/.bashrc
{% endif %}
