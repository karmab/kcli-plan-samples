## Purpose

This repository provides a plan which deploys a vm where:
- openshift-baremetal-install is downloaded or compiled from source (with an additional list of PR numbers to apply)
- stop the nodes to deploy through ipmi
- launch the install against a set of baremetal nodes

## Why

To deploy baremetal using `bare minimum` on the provisioning node

## Requirements

### Data

- a valid install-config.yaml 
- a pull secret to put in openshift_pull.json

### on the provisioning node

- libvirt daemon (with fw_cfg support)
- two physical bridges:
    - baremetal with a nic from the external network
    - provisioning with a nic from the provisioning network. Ideally assign it an ip of 172.22.0.1/24

Here's a script you can run on the provisioning node for that

```
export PROV_CONN=eno1
export MAIN_CONN=eno2
sudo nmcli connection add ifname provisioning type bridge con-name provisioning
sudo nmcli con add type bridge-slave ifname "$PROV_CONN" master provisioning
sudo nmcli connection add ifname baremetal type bridge con-name baremetal
sudo nmcli con add type bridge-slave ifname "$MAIN_CONN" master baremetal
sudo nmcli con down "System $MAIN_CONN"; sudo pkill dhclient; sudo dhclient baremetal
sudo nmcli connection modify provisioning ipv4.addresses 172.22.0.1/24 ipv4.method manual
sudo nmcli con down provisioning
sudo nmcli con up provisioning
```

## Launch

```
kcli create plan
```

## Interacting in the vm

The deployed vm comes with a set of helpers for you:
- scripts run.sh and clean.sh allow you to manually launch an install or clean a failed one
- you can run *openstack baremetal node list* during deployment to check the status of the provisioning of the nodes (Give some time after launching an install before ironic is accessible).
- script *ipmi.py* can be used to check the power status of the baremetal node or to stop them (using `ipmi.py off`)

## Parameters

|Parameter                 |Default Value                      |
|--------------------------|-----------------------------------|
|image                     |CentOS-7-x86_64-GenericCloud.qcow2 |
|network                   |default                            |
|pool                      |default                            |
|memory                    | 12288                             |
|disk_size                 | 20                                |
|provisioning_interface    |eno1                               |
|provisioning_net          |provisioning                       |
|provisioning_ip           |172.22.0.3                         |
|provisioning_cidr         |24                                 |
|provisioning_range        | 172.22.0.10,172.22.0.100          |
|provisioning_installer_ip |172.22.0.253                       |
|cache                     |False                              |
|baremetal_net             |baremetal                          |
|pullsecret_path           | ./openshift_pull.json             |
|installconfig_path        | ./install-config.yaml             |
|run                       |True                               |
|build                     |False                              |
|prefix                    |openshift                          |
|prs                       |[]                                 |
|go_version                |1.12.12                            |
|tag                       |4.3                                |


## I want to use virtual masters and physical workers

Although this is not the primary scope of this repository, you can

- make sure that you have proper dns set for the virtual masters. The masters need to be named xx-master-$num for openshift install to succeed
- make sure that you have dhcp entries associated to the virtual masters macs . Collect those macs
- create 3 empty master vms using the `masters.yml` plan and by passing as a parameter the list of external macs
 
 `kcli create plan -f masters.yml -P external_macs=[XX,YY,ZZ]`
- set vbmcd dameon and client on the provisioning node
- create vbmc ports for them with the following commands to run on the provisioning node
```
MASTERS=3
for num in $(seq 0 $(( MASTERS -1 )))` ; do
vbmc add openshift-master-$NUM --port 623$NUM --username admin --password password --libvirt-uri qemu:///system
vbmc start openshift-master-$NUM
done
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
