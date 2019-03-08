url="https://{{ host }}/ovirt-engine/api"
user="{{ user }}"
password="{{password }}"
plan="{{ plan }}"

VMIDS=`curl -sk -H "Accept: application/xml" -u  "${user}:${password}" "${url}/vms?search=plan=${plan}*" | grep '<vm href=' | sed 's/.*id="\(.*\).*">/\1/'`

sleep 240
for vmid in $VMIDS ; do
  name=`curl -sk -H "Accept: application/xml" -u  "${user}:${password}" "${url}/vms/${vmid}" |  grep -m1 '<name>'| sed 's@.*<name>\(.*\)</name>@\1@'`
  ip=`curl -sk -H "Accept: application/xml" -u  "${user}:${password}" "${url}/vms/${vmid}/reporteddevices" | grep -v : | grep -m1 address | sed 's@.*<address>\(.*\)</address>@\1@'`
  newname=${name}.${ip}.xip.io
  echo "Substituting ${name} for ${newname} in inventory"
  sed -i "s/${name}/${newname}/g" /root/inventory
  ssh -o 'StrictHostKeyChecking=no' root@${ip} hostnamectl set-hostname ${newname}
done
