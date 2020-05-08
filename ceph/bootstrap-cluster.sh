curl --silent --remote-name --location https://raw.githubusercontent.com/ceph/ceph/master/src/cephadm/cephadm
chmod +x cephadm
mkdir -p /etc/ceph
mon_ip=$(ifconfig eth0  | grep 'inet ' | awk '{ print $2}')
./cephadm bootstrap --mon-ip $mon_ip --allow-fqdn-hostname --initial-dashboard-password halamadrid
fsid=$(cat /etc/ceph/ceph.conf | grep fsid | awk '{ print $3}')
{% for number in range(1, nodes) %}
  ssh-copy-id -f -i /etc/ceph/ceph.pub  -o StrictHostKeyChecking=no root@{{prefix }}-node-0{{ number }}
  sudo ./cephadm shell --fsid $fsid -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring ceph orch host add {{prefix }}-node-0{{ number }}.{{domain}}
{% endfor %}
sudo ./cephadm shell --fsid $fsid -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring ceph orch apply osd --all-available-devices
