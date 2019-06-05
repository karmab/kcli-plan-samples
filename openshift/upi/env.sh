#!/bin/bash

export numcpus=8
export template=rhcos-410.8.20190520.1-qemu.qcow2
export network=default
export use_br=true
export extra_disk=true
export master_memory=16384
export worker_memory=16384
export bootstrap_memory=6144
export haproxy_memory=1024
export disk_size=30
export extra_disk_size=70
export cluster=sjr1
export masters=1
export workers=3
