## Purpose

This repository provides a plan which deploys a vm where
- openshift-baremetal-install is downloaded or compiled from source (with an additional list of PRS to apply)
- stop the nodes to deploy through ipmi
- launch the install against a set of baremetal nodes

## Why
to deploy baremetal using bare minimum on the provisioning node

## What is needed on the provisioning node

- libvirt daemon (with fw_cfg support)
- two physical bridges:
    - baremetal with a nic from the external network
    - provisioning with a nic from the provisioning network. Ideally assign it an ip of 172.22.0.1/24

## Launch

Gather your install-config.yaml and put your pull secret in openshift_pull.json

```
kcli create plan
```

## Known issues

During the install, you will need to manually create a config map for the baremetal operator to properly launch.
Adapt the *metal3-cm.yml.sample* file, Copy it to *metal3-cm.yml* and run the following commands:

```
oc create -f metal3-cm.yml -n openshift-machine-api
```

## Parameters

|Parameter          |Default Value                      |
|-------------------|-----------------------------------|
|image              |CentOS-7-x86_64-GenericCloud.qcow2 |
|network            |default                            |
|pool               |default                            |
|memory             | 12288                             |
|provisioning_net   |provisioning                       |
|baremetal_net      |baremetal                          |
|cluster            |mycluster                          |
|pullsecret_path    | ./openshift_pull.json             |
|installconfig_path | ./install-config.yaml             |
|run                |True                               |
|build              |False                              |
|prefix             |openshift                          |
|prs                |[]                                 |
|go_version         |1.12.12                            |

## I want to use virtual masters

although this is not the primary scope of this repository, you can

- set vbmcd dameon and client on the provisioning node
- create 3 empty master vms using the `masters.yml` plan
- create vbmc ports for them with the following commands to run on the provisioning node
```
vbmc add openshift-master-0 --port 6230 --username admin --password password --libvirt-uri qemu:///system
vbmc start openshift-master-0
vbmc add openshift-master-1 --port 6231 --username admin --password password --libvirt-uri qemu:///system
vbmc start openshift-master-1
vbmc add openshift-master-2 --port 6232 --username admin --password password --libvirt-uri qemu:///system
vbmc start openshift-master-2
```

- add the masters information in your install-config.yaml with lines similar to this one and by changing NUM depending on the master and PROVISIONING_IP to the ip of your provisioning node

```
- name: openshift-master-$NUM
  role: master
  bmc:
    address: ipmi://$PROVISIONING_IP:623$NUM
    username: admin
    password: password
  bootMACAddress: aa:bb:cc:dd:ee:0$NUM
  hardwareProfile: libvirt
```

- launch the install as usual
