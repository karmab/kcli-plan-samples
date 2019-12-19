echo export KUBECONFIG=/root/ocp/auth/kubeconfig >> /root/.bashrc
echo export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=registry.svc.ci.openshift.org/ocp/release:{{ tag }} >> /root/.bashrc
echo export OS_CLOUD=metal3-bootstrap >> /root/.bashrc
bash /root/network.sh
export PATH=/root/bin:$PATH
mkdir /root/bin
cd /root/bin
bash /root/get_clients.sh
{% if not build %}
bash /root/get_installer.sh
{% endif %}

cd /root
if [ -z "$COMMIT_ID" ] ; then
export COMMIT_ID=$(openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')
fi
export RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .images.openstack.path | sed 's/"//g')
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')
envsubst < metal3-config.yaml.sample > metal3-config.yaml

PROVISIONING_IP=$(grep libvirtURI install-config.yaml | awk -F'/' '{ print $3 }' | awk -F'@' '{ print $2 }')
ssh-keyscan -H $PROVISIONING_IP >> ~/.ssh/known_hosts
echo -e "Host=*\nStrictHostKeyChecking=no\n" > .ssh/config
{% if run %}
bash run.sh
sed -i "s/metal3-bootstrap/metal3/" /root/.bashrc
{% endif %}
