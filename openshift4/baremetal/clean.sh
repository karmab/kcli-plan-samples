rm -rf /root/{{cluster }}
BOOTSTRAP=$(virsh list --name | grep {{cluster}})
export LIBVIRT_DEFAULT_URI=$(grep libvirtURI install-config.yaml | sed 's/libvirtURI: //' | xargs)
virsh destroy $BOOTSTRAP
virsh undefine $BOOTSTRAP
virsh vol-delete $BOOTSTRAP default
virsh vol-delete $BOOTSTRAP.ign default
