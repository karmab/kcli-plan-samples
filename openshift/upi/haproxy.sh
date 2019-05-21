yum -y install haproxy
systemctl enable haproxy
cp haproxy.cfg /etc/haproxy
systemctl start haproxy
