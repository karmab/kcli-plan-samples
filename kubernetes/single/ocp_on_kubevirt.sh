#!/bin/bash
sleep 30
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
service iptables save
echo fedora | passwd --stdin fedora
mkdir /home/fedora/.ssh
chmod 700 /home/fedora/.ssh
echo PUBKEY >> /home/fedora/ssh/authorized_keys
chmod 600 /home/fedora/.ssh/authorized_keys
yum -y install wget docker git
wget -P /root/ https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
mv /root/jq-linux64 /usr/bin/jq
chmod u+x /usr/bin/jq
systemctl enable docker
sed -i "s@# INSECURE_REGISTRY=.*@INSECURE_REGISTRY='--insecure-registry 172.30.0.0/16'@" /etc/sysconfig/docker
wget -O /root/oc.tar.gz https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
cd /root ; tar zxvf oc.tar.gz
mv /root/openshift-origin-client-tools-*/oc /usr/bin
rm -rf  /root/openshift*
curl -L https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl -o /usr/bin/kubectl
chmod +x /usr/bin/kubectl
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
sed -i 's@OPTIONS=.*@OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"@' /etc/sysconfig/docker
systemctl start docker --ignore-dependencies
export HOME=/root
export DNS=`ip a l  eth0 | grep 'inet ' | cut -d' ' -f6 | awk -F'/' '{ print $1}'`.xip.io
oc cluster up --public-hostname ${DNS} --routing-suffix ${DNS} --enable=router,registry,web-console,persistent-volumes,rhel-imagestreams
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin {{ admin_user }}
docker update --restart=always origin
