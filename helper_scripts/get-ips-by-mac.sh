#!/bin/bash
# Validate that at least one VM name and the file path are provided as arguments
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <VM_NAME1> [<VM_NAME2> ...] <FILE_PATH>"
  exit 1
fi

# Extract the file path from the last argument
FILE_PATH=${!#}

# Validate that the file path is a regular file
if [[ ! -f $FILE_PATH ]]; then
  echo "Error: '$FILE_PATH' is not a regular file"
  exit 1
fi

VM_NAMES=${@:1:$#-1}

SUBNET=$(ip route | awk '/default/ {print $3}' | awk '{split($0,a,"."); printf("%s.%s.%s.0/24",a[1],a[2],a[3])}')

# Iterate over the list of VM names and get the IP address for each one
for VM_NAME in $VM_NAMES; do
    # Get the MAC address of the VM's network interface
    MAC_ADDRESS=$(sudo virsh domiflist $VM_NAME | awk '{print $5}' | tail -n 2)
    echo "MAC address for $VM_NAME: $MAC_ADDRESS"
    # Use nmap to search for the MAC address and retrieve the associated IP address
    IP_ADDRESS=$(sudo nmap -sP ${SUBNET}| grep  -B2  ${MAC_ADDRESS}  | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' || arp -an  | grep ${MAC_ADDRESS} | awk '{print $2}' | sed 's/[()]//g')

    # Print the MAC address and associated IP address
    echo "IP address for $MAC_ADDRESS: $IP_ADDRESS"

    # Replace the IP address in the file for the current VM name
    sudo sed -i "s/$VM_NAME/$IP_ADDRESS/g" $FILE_PATH
done
