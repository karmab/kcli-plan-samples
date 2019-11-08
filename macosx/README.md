How to simply run a macosx vm

# Preparation 

```
alias fetchmacosx='podman run -it --rm -v $PWD:/prout karmab/fetchmacosx'
fetchmacosx -o /prout
wget https://github.com/foxlet/macOS-Simple-KVM/raw/master/tools/dmg2img
chmod u+x dmg2img
./dmg2img BaseSystem.dmg BaseSystem.img
wget https://github.com/karmab/kcli-plans/raw/master/macosx/ESP.qcow2
wget https://github.com/karmab/kcli-plans/raw/master/macosx/OVMF_CODE.fd
wget https://github.com/karmab/kcli-plans/raw/master/macosx/OVMF_VARS-1024x768.fd
qemu-img create -f qcow2 macosx.qcow2 64G
```
