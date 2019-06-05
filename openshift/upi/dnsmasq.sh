yum -y install dnsmasq
cp /root/dnsmasq.conf /etc
systemctl enable --now dnsmasq
