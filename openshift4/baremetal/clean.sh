#!/usr/bin/env bash

rm -rf /root/ocp
export LIBVIRT_DEFAULT_URI=$(grep libvirtURI install-config.yaml | sed 's/libvirtURI: //' | xargs)
cluster=$(yq r install-config.yaml metadata.name)
bootstrap=$(virsh list --name | grep "$cluster.*bootstrap")
if [ "$bootstrap" != "" ] ; then
for vm in $bootstrap ; do
virsh destroy $vm
virsh undefine $vm
virsh vol-delete $vm default
virsh vol-delete $vm.ign default
done
fi
