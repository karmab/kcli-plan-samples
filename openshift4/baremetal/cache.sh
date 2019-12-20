yum -y install httpd
systemctl enable --now httpd
cd /var/www/html
if [ -z "$COMMIT_ID" ] ; then
export COMMIT_ID=$(openshift-baremetal-install version | grep '^built from commit' | awk '{print $4}')
fi
export RHCOS_URI=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq .images.openstack.path | sed 's/"//g')
export RHCOS_PATH=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json | jq .baseURI | sed 's/"//g')
export RHCOS_SHA_UNCOMPRESSED=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq -r '.images.qemu["uncompressed-sha256"]')
export RHCOS_SHA_COMPRESSED=$(curl -s -S https://raw.githubusercontent.com/openshift/installer/$COMMIT_ID/data/data/rhcos.json  | jq -r '.images.qemu.sha256')
curl -L ${RHCOS_PATH}${RHCOS_URI} > $RHCOS_URI
echo $RHCOS_SHA_UNCOMPRESSED $RHCOS_URI > $SHORT_URI.sha256sum
#sed -i "/apiVIP/i\ \ \ \ bootstrapOSImage: http://{{ provisioning_ip }}/$RHCOS_URI?sha256=$RHCOS_SHA_UNCOMPRESSED" /root/install-config.yaml
#sed -i "/apiVIP/i\ \ \ \ clusterOSImage: http://{{ provisioning_ip }}/$RHCOS_URI?sha256=$RHCOS_SHA_COMPRESSED" /root/install-config.yaml
SPACES=$(grep apiVIP /root/install-config.yaml | sed 's/apiVIP.*//' | sed 's/ /\\ /'g)
sed -i "/apiVIP/i${SPACES}bootstrapOSImage: http://{{ provisioning_ip }}/$RHCOS_URI?sha256=$RHCOS_SHA_UNCOMPRESSED" /root/install-config.yaml
sed -i "/apiVIP/i${SPACES}clusterOSImage: http://{{ provisioning_ip }}/$RHCOS_URI?sha256=$RHCOS_SHA_COMPRESSED" /root/install-config.yaml
