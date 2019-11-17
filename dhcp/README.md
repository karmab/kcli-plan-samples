this plan demonstrates how to deploy a custom dhcp server in a network lacking it, and serving only dhcp for a specific set of nodes, based on their mac addresses

# How to use

Deploy the dhcp helper node by providing a parameter file containing ips, macs and node names

```
kcli create plan --paramfile params.sample
```

# Testing (on libvirt)

You can deploy a sample network without dhcp

```
kcli create network --nodhcp -c 192.168.100.0/24 nodhcpnet
```

Then you woud deploy the dhcp helper node and finally, deploy a sample plan with vms matching the specs of you parameter file

```
kcli create plan -f vms.sample --paramfile params.sample
```
