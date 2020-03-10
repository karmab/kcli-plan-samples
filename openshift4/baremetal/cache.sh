#!/usr/bin/env bash

yum -y install httpd
systemctl enable --now httpd
cd /var/www/html
if [ -z "$COMMIT_ID" ] ; then
export COMMIT_ID=$(openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')
fi
export RHCOS_OPENSTACK_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq .images.openstack.path | sed 's/"//g')
export RHCOS_QEMU_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq .images.qemu.path | sed 's/"//g')
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')
export RHCOS_QEMU_SHA_UNCOMPRESSED=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq -r '.images.qemu["uncompressed-sha256"]')
export RHCOS_OPENSTACK_SHA_COMPRESSED=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq -r '.images.openstack.sha256')
curl -L ${RHCOS_PATH}${RHCOS_QEMU_URI} > $RHCOS_QEMU_URI
curl -L ${RHCOS_PATH}${RHCOS_OPENSTACK_URI} > $RHCOS_OPENSTACK_URI
SPACES=$(grep apiVIP /root/install-config.yaml | sed 's/apiVIP.*//' | sed 's/ /\\ /'g)
export PROVISIONING_IP=$(ip -o addr show {{ provisioning_net }} | head -1 | awk '{print $4}' | cut -d'/' -f1)
sed -i "/apiVIP/i${SPACES}bootstrapOSImage: http://${PROVISIONING_IP}/${RHCOS_QEMU_URI}?sha256=${RHCOS_QEMU_SHA_UNCOMPRESSED}" /root/install-config.yaml
sed -i "/apiVIP/i${SPACES}clusterOSImage: http://${PROVISIONING_IP}/${RHCOS_OPENSTACK_URI}?sha256=${RHCOS_OPENSTACK_SHA_COMPRESSED}" /root/install-config.yaml
