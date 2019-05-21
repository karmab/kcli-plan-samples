setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
yum -y install haproxy
systemctl enable haproxy
cp -f /root/haproxy.cfg /etc/haproxy
systemctl start haproxy
