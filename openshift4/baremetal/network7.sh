yum -y install libvirt-libs libvirt-client ipmitool bridge-utils centos-release-openstack-train mkisofs tmux screen
yum -y install python2-openstackclient python2-ironicclient
echo -e "DEVICE=baremetal\nTYPE=Bridge\nONBOOT=yes\nNM_CONTROLLED=no\nBOOTPROTO=dhcp" > /etc/sysconfig/network-scripts/ifcfg-baremetal
echo -e "DEVICE=eth0\nTYPE=Ethernet\nONBOOT=yes\nNM_CONTROLLED=no\nBRIDGE=baremetal" > /etc/sysconfig/network-scripts/ifcfg-eth0
ifup eth0
ifup baremetal
echo -e "DEVICE=provisioning\nTYPE=Bridge\nONBOOT=yes\nNM_CONTROLLED=no\nBOOTPROTO=static\nIPADDR={{ provisioning_installer_ip }}\nPREFIX={{ provisioning_cidr }}" > /etc/sysconfig/network-scripts/ifcfg-provisioning
echo -e "DEVICE=eth1\nTYPE=Ethernet\nONBOOT=yes\nNM_CONTROLLED=no\nBRIDGE=provisioning" > /etc/sysconfig/network-scripts/ifcfg-eth1
ifup eth1
ifup provisioning
