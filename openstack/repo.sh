systemctl disable --now firewalld
systemctl disable --now NetworkManager
systemctl enable --now network
dnf config-manager --enable powertools
yum install -y centos-release-openstack-{{ version }} 
echo centos >/etc/yum/vars/contentdir
