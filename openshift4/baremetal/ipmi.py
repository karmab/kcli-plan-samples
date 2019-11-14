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
        print("ipmitool -H %s -U %s -P %s -I lanplus chassis power %s" % (address, username, password, action))
