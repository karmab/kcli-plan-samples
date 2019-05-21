yum -y install dnsmasq
echo address=/{{ wildcardname }}/{{ wildcardip }} >> /etc/dnsmasq.conf
systemctl enable dnsmasq
systemctl start dnsmasq
