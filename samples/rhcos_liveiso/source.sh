#!/usr/bin/bash

sleep 30
ignition_url='http://192.168.1.6/worker.ign'
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

curl ${ignition_url} > /home/core/config.ign
cmd="coreos-installer install --firstboot-args=${firstboot_args} --ignition=/home/core/config.ign ${install_device}"
if $cmd; then
  echo "Install Succeeded!"
  # systemctl disable first-boot
  reboot
else
  echo "Install Failed!"
  exit 1
fi
