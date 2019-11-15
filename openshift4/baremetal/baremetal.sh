echo export KUBECONFIG=/root/{{ cluster }}/auth/kubeconfig >> /root/.bashrc
yum -y install libvirt-libs ipmitool bridge-utils
echo -e "DEVICE=baremetal\nTYPE=Bridge\nONBOOT=yes\nNM_CONTROLLED=no\nBOOTPROTO=dhcp" > /etc/sysconfig/network-scripts/ifcfg-baremetal
echo -e "DEVICE=eth0\nTYPE=Ethernet\nONBOOT=yes\nNM_CONTROLLED=no\nBRIDGE=baremetal" > /etc/sysconfig/network-scripts/ifcfg-eth0
ifup eth0
ifup baremetal
echo -e "DEVICE=provisioning\nTYPE=Bridge\nONBOOT=yes\nNM_CONTROLLED=no\nBOOTPROTO=static\nIPADDR=172.22.0.253\nNETMASK=255.255.255.0" > /etc/sysconfig/network-scripts/ifcfg-provisioning
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
export PULL_SECRET="openshift_pull.json"
export OPENSHIFT_RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}' | xargs)
oc adm release extract --registry-config $PULL_SECRET --command=openshift-baremetal-install --to . $OPENSHIFT_RELEASE_IMAGE
{% endif %}

if [ -z "$COMMIT_ID" ] ; then
export COMMIT_ID=$(./openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')
fi
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
mv jq /usr/bin
chmod u+x /usr/bin/jq
export RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.openstack.path)
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.baseURI)
envsubst metal3-config.yml.sample > metal3-config.yml

mkdir {{ cluster }}
cp install-config.yaml {{ cluster }}
PROVISIONING_IP=$(grep libvirtURI install-config.yaml.u08 | awk -F'/' '{ print $3 }' | awk -F'@' '{ print $2 }')
ssh-keyscan -H $PROVISIONING_IP >> ~/.ssh/known_hosts
echo -e "Host=*\nStrictHostKeyChecking=no\n" > .ssh/config
{% if run %}
python ipmi.py off
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=registry.svc.ci.openshift.org/ocp/release:{{ tag }}
openshift-baremetal-install --dir {{ cluster }} --log-level debug create cluster
{% endif %}
