rm -rf /root/ocp
export LIBVIRT_DEFAULT_URI=$(grep libvirtURI install-config.yaml | sed 's/libvirtURI: //' | xargs)
CLUSTER=$(cat install-config.yaml | yq .metadata.name)
BOOTSTRAP=$(virsh list --name | grep $CLUSTER-bootstrap)
virsh destroy $BOOTSTRAP
virsh undefine $BOOTSTRAP
virsh vol-delete $BOOTSTRAP default
virsh vol-delete $BOOTSTRAP.ign default
