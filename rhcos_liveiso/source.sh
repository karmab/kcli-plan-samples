#!/usr/bin/bash

sleep 20
ignition_url="http://karmatron.mooo.com/worker.ign"
networks_args='ip=192.168.122.205::192.168.122.1:24:biloute.karmalabs.com:ens3:none'                          │·················
dns_args='nameserver=192.168.122.1'
firstboot_args='console=tty0'
if [ -b /dev/vda ]; then
  install_device='/dev/vda'
elif [ -b /dev/sda ]; then
  install_device='/dev/sda'
elif [ -b /dev/nvme0 ]; then
  install_device='/dev/nvme0'
else
  echo "Can't find appropriate device to install to"
  exit 1
fi

curl ${ignition_url} > /root/config.ign
cmd="coreos-installer install --firstboot-args=\"${firstboot_args}\" --append-kargs=\"$(network_args)\" --append-kargs=\"$(dns_args)\" --ignition=/root/config.ign ${install_device}"
if $cmd; then
  echo "Install Succeeded!"
  reboot
else
  echo "Install Failed!"
  exit 1
fi
