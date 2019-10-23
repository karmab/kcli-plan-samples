dnf -y remove libnfsidmap
dnf -y install libvirt libvirt-daemon-driver-qemu qemu-kvm NetworkManager
sudo usermod -aG qemu,libvirt fedora
echo -e "server=/apps-crc.testing/192.168.130.11\nserver=/crc.testing/192.168.130.11" > /etc/NetworkManager/dnsmasq.d/crc.conf
echo -e "[main]\ndns=dnsmasq\n" > /etc/NetworkManager/conf.d/crc-nm-dnsmasq.conf
systemctl enable --now libvirtd NetworkManager
curl https://mirror.openshift.com/pub/openshift-v4/clients/crc/latest/crc-linux-amd64.tar.xz > /root/crc.tar.xz
tar xvf /root/crc.tar.xz -C /usr/bin --strip-components=1
cp /tmp/pull-secret.txt /home/fedora
chown fedora.fedora /home/fedora/pull-secret.txt
su - fedora -c "crc setup || crc setup"
su - fedora -c "crc start -p /home/fedora/pull-secret.txt -m {{ vm_memory }} -c {{ vm_numcpus }}"
echo export PATH="/home/fedora/.crc/bin:\$PATH"  >> /home/fedora/.bashrc
echo export KUBECONFIG=/home/fedora/.crc/machines/crc/kubeconfig >> /home/fedora/.bashrc
{% if monitoring %}
oc scale --replicas=1 statefulset --all -n openshift-monitoring; oc scale --replicas=1 deployment --all -n openshift-monitoring
{% endif %}
