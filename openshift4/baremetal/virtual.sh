#!/usr/bin/env bash

set -euo pipefail

yum -y install pkgconf-pkg-config libvirt-devel gcc python3-libvirt
pip3 install virtualbmc
export PATH=/usr/local/bin:$PATH
vbmcd
PYTHON="python"
which python3 >/dev/null 2>&1 && PYTHON="python3"
$PYTHON /root/vbmc.py
api_vip=$(grep apiVIP /root/install-config.yaml | awk -F: '{print $2}' | xargs)
cluster=$(grep -m 1 name /root/install-config.yaml | awk -F: '{print $2}' | xargs)
domain=$(grep baseDomain /root/install-config.yaml | awk -F: '{print $2}' | xargs)
IP=$(hostname -I | cut -f1 -d' ')
sed -i "s/DONTCHANGEME/$IP/" /root/install-config.yaml
echo $api_vip api.$cluster.$domain >> /etc/hosts
