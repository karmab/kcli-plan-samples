K8S="{{ k8s_version }}"
[ "$K8S" == "latest" ] && K8S=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases|grep tag_name| grep -v alpha | sort -V | tail -1 | awk -F':' '{print $2}' | sed 's/,//' | xargs | awk -F'-' '{print $1}' | sed 's/v//')
yum -y install wget git
wget -P /root/ https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
mv /root/jq-linux64 /usr/bin/jq
chmod u+x /usr/bin/jq
echo net.bridge.bridge-nf-call-iptables=1 >> /etc/sysctl.d/99-sysctl.conf
sysctl -p
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
yum install -y docker kubelet-$K8S kubectl-$K8S kubeadm-$K8S
echo kubernetesVersion: $K8S >> /root/config.yml
sed -i "s/--selinux-enabled //" /etc/sysconfig/docker
systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet
