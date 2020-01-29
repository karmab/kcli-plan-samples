#!/usr/bin/env python

import os
import yaml

installfile = "install-config.yaml"
with open(installfile) as f:
    data = yaml.safe_load(f)
    uri = data['platform']['baremetal']['libvirtURI']
    hosts = data['platform']['baremetal']['hosts']
    for host in hosts:
        name = host['name']
        address = host['bmc']['address'].replace('ipmi://', '')
        if not address.startswith('DONTCHANGEME'):
            continue
        if ':' in address:
            address, port = address.split(':')
            port = '--port %s' % port
        else:
            port = ''
        username = host['bmc']['username']
        password = host['bmc']['password']
        cmd = "vbmc add %s %s --username %s --password %s --libvirt-uri %s; vbmc start %s" % (name, port, username,
                                                                                              password, uri, name)
        os.system(cmd)
