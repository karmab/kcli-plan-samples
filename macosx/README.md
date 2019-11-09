How to simply run a macosx vm

# Preparation 

Run the following on target hypervisor, in you default pool path (typically `/var/lib/libvirt/images`)

```
podman run -it --rm -v $PWD:/x karmab/fetchmacosx -o /x -v 10.15
wget https://github.com/foxlet/macOS-Simple-KVM/raw/master/tools/dmg2img
chmod u+x dmg2img
./dmg2img BaseSystem.dmg BaseSystem.img
wget https://github.com/karmab/kcli-plans/raw/master/macosx/ESP.qcow2
wget https://github.com/karmab/kcli-plans/raw/master/macosx/OVMF_CODE.fd
wget https://github.com/karmab/kcli-plans/raw/master/macosx/OVMF_VARS-1024x768.fd
```

# deploy your macosx vm

```
kcli create plan -f macosx.yml
```
