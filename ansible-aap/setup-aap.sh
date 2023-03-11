#!/bin/bash 

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root!"
    exit 1
fi

ANSIBLE_AAP=ansible-aap
ANSIBLE_HUB=ansible-hub
POSTGRES=postgres
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
ssh-copy-id root@${ANSIBLE_AAP}
ssh-copy-id root@${ANSIBLE_HUB}
ssh-copy-id root@${POSTGRES}

cd $HOME/ocp4-ai-svc-universal-aap-configs



sudo cat >inventory_dev.yml<<EOF
---
all:
  children:
    dev:
      hosts:
        ${ANSIBLE_AAP}
      vars:
        connection: local

    automationcontroller:
      hosts:
        ${ANSIBLE_AAP}:

    automationhub:
      hosts:
        ${ANSIBLE_HUB}:

    # can be automationhub if you do not have a specific server for this
    builder:
      hosts:
        ${ANSIBLE_HUB}:

    # only needed if installing AAP with automation, can be removed if you are not
    database:
      hosts:
        ${POSTGRES}:
  vars:
    env: dev
...
EOF

ansible-playbook -i inventory_dev.yml playbooks/install_aap.yml --ask-vault-pass 


ansible-playbook -i inventory_dev.yml -l dev playbooks/install_configure.yml --ask-vault-pass -e "env=dev" 

ansible-playbook -i inventory_dev.yml -l dev playbooks/hub_config.yml --ask-vault-pass