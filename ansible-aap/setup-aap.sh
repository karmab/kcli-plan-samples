#!/bin/bash 

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root!"
    exit 1
fi

ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
ssh-copy-id root@ansible-aap
ssh-copy-id root@ansible-hub
ssh-copy-id root@postgres

cd $HOME/ocp4-ai-svc-universal-aap-configs

cat >vaults/dev.yml<<EOF
---
cloud_token: 'this is the one from console.redhat.com'
offline_token: 'this is the one linked below about api token'
rh_username: 'redhat user login (this is used to attach your subs to controller)'
rh_password: 'password for redhat account'
root_machine_pass: 'password for root user on builder (if not root user more changes will need to be made)'
ah_token_password: 'this will create and use this password can be generated'
controller_api_user_pass: 'this will create and use this password can be generated'
controller_pass: 'admin account pass for controller, if none is given it will default to Password1234!'
ah_pass: 'hub admin account pass, if none is given it will default to Password1234!'
vault_pass: 'the password to decrypt this vault'
EOF

sudo cat >inventory_dev.yml<<EOF
---
all:
  children:
    dev:
      hosts:
        ansible-aap
      vars:
        connection: local

    automationcontroller:
      hosts:
        ansible-aap:

    automationhub:
      hosts:
        ansible-hub:

    # can be automationhub if you do not have a specific server for this
    builder:
      hosts:
        ansible-hub:

    # only needed if installing AAP with automation, can be removed if you are not
    database:
      hosts:
        postgres:
  vars:
    env: dev
...
EOF

ansible-playbook -i inventory_dev.yml playbooks/install_aap.yml --ask-vault-pass 


ansible-playbook -i inventory_dev.yml -l dev playbooks/install_configure.yml --ask-vault-pass -e "env=dev" 

