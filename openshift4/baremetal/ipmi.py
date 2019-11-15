#!/usr/bin/env python

import os
import sys
import yaml

action = sys.argv[1] if len(sys.argv) > 1 else 'status'
installfile = "install-config.yaml"
with open(installfile) as f:
    data = yaml.load(f)
    hosts = data['platform']['baremetal']['hosts']
    for host in hosts:
        name = host['name']
        address = host['bmc']['address'].replace('ipmi://', '')
        username = host['bmc']['username']
        password = host['bmc']['password']
        cmd = "ipmitool -H %s -U %s -P %s -I lanplus chassis power %s" % (address, username, password, action)
        print(cmd)
        os.system(cmd)
