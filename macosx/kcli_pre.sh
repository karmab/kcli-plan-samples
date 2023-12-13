#!/usr/bin/env bash
{% set versions = ['high-sierra', 'mojave', 'catalina', 'big-sur', 'monterey', 'ventura'] %}
{% if version not in versions %}
echo Invalid version. Should be between {{ versions }} && exit 0
{% endif %}
kcli list image | grep -q OpenCore.qcow2
if [ "$?" != "0" ] ; then
  curl -Lk https://github.com/kholia/OSX-KVM/raw/master/OpenCore/OpenCore.qcow2 > /var/lib/libvirt/images/OpenCore.qcow2
fi
export PATH=.:$PATH
kcli list image | grep -q {{ version|capitalize }}
if [ "$?" != "0" ] ; then
  which fetch-macOS-v2.py || (curl https://raw.githubusercontent.com/kholia/OSX-KVM/master/fetch-macOS-v2.py > fetch-macOS-v2.py ; chmod +x fetch-macOS-v2.py)
  fetch-macOS-v2.py -s {{ version }}
  [ "$(which dmg2img)" != "" ] || dnf -y install dmg2img
  dmg2img -i BaseSystem.dmg /var/lib/libvirt/images/{{ version|capitalize }}.img
fi
