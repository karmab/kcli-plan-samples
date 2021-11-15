# rm -rf source.ign
# kcli create asset -f source.yml > source.ign
kcli create asset -i rhcos46 -P scripts=[source.sh] > source.ign
alias coreos-installer='podman run --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v $PWD:/data -w /data quay.io/coreos/coreos-installer:release'
curl https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest-4.6/rhcos-live.x86_64.iso > rhcos-live.x86_64.iso
coreos-installer iso ignition embed -i source.ign rhcos-live.x86_64.iso
#kcli create vm -P iso=klive.iso -P nets=[baremetal]
