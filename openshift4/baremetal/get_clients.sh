mkdir /root/bin
cd /root/bin
curl --silent https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz > oc.tar.gz
tar zxf oc.tar.gz
rm -rf oc.tar.gz
chmod +x oc

curl -Ls https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > /root/bin/jq
chmod u+x /root/bin/jq
curl -Ls https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 > /root/bin/yq
chmod u+x /root/bin/yq
