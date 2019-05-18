engine-config -s 'UserDefinedVMProperties=ignitiondata=.*' --cver='{{ version }}'
systemctl restart ovirt-engine
cp /root/90_ignition /usr/libexec/vdsm/hooks/before_vm_start
chmod 755 /usr/libexec/vdsm/hooks/before_vm_start/90_ignition
restorecon -Frv /usr/libexec/vdsm/hooks/before_vm_start/90_ignition
systemctl restart vdsmd
