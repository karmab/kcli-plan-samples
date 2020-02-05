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
- scripts deploy.sh and clean.sh allow you to manually launch an install or clean a failed one
- you can run *openstack baremetal node list* during deployment to check the status of the provisioning of the nodes (Give some time after launching an install before ironic is accessible).
- script *ipmi.py* can be used to check the power status of the baremetal node or to stop them (using `ipmi.py off`)

## Parameters

|Parameter                 |Default Value                      |
|--------------------------|-----------------------------------|
|image                     |centos8                            |
|image_url                 |                                   |
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
|disconnected              |False                              |
|baremetal_net             |baremetal                          |
|pullsecret_path           | ./openshift_pull.json             |
|installconfig_path        | ./install-config.yaml             |
|deploy                    |True                               |
|wait_workers              |True                               |
|build                     |False                              |
|prefix                    |openshift                          |
|prs                       |[]                                 |
|go_version                |1.12.12                            |
|tag                       |4.4                                |
|rhnwait                   |30                                 |
|cnf                       |False                              |
|cnf_features              |performance,ptp,sriov,dpdk, sctp   |
|virtual                   |false                              |

## I want to use virtual masters and physical workers

Although this is not the primary scope of this repository, you can.

- make sure you have proper dns set for the virtual masters. The masters need to be named xx-master-$num for openshift install to succeed
- make sure you have dhcp entries associated to the virtual masters macs. Collect those macs.
- create 3 empty master vms using the `masters.yml` plan and by passing as a parameter the list of external macs
 
 `kcli create plan -f masters.yml -P external_macs=[XX,YY,ZZ]`

- copy the install-config.yaml.virtual_masters to install-config.yaml and edit it to add correct apiVip, dnsVip and ingressVip. Let the DONTCHANGEME key as it is for your virtual masters, as virtual bmc will be deployed on the installer vm and those ipmi ports added.
- launch the install as usual but setting virtual to True in your parameters file
