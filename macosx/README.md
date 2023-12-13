This plan allows to create a vm for installing macosx

# Requirements

It relies on additional assets, in particular from https://github.com/kholia/OSX-KVM:

- `https://raw.githubusercontent.com/kholia/OSX-KVM/master/fetch-macOS-v2.py`
- `https://github.com/kholia/OSX-KVM/blob/master/OpenCore/OpenCore.qcow2`
- `dmg2img`

# How to use

```
kcli create plan myosxvm
```

The following parameters can be tweaked:

- numcpus
- memory
- disk_size
- network
- version

Then connect via console to the vm and launch the installation (I had to first erase the target disk using disk utility)
