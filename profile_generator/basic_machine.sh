#!/bin/bash
# this is just a test script to test the profile_generator
export ANSIBLE_SAFE_VERSION="0.0.4"
PROFILES_FILE="kcli-profiles.yml"
ANSIBLE_VAULT_FILE="/home/${USER}/quibinode_navigator/inventories/localhost/group_vars/control/vault.yml"
KCLI_CONFIG_DIR="/root/.kcli"
KCLI_CONFIG_FILE="${KCLI_CONFIG_DIR}/profiles.yml"

function check_kcli_plan {
  if [ -d $HOME/kcli-plan-samples ]; then
    echo "kcli plan already exists"
  else
    cd $HOME
    git clone https://github.com/tosin2013/kcli-plan-samples.git
  fi
}

function install_ansiblesafe {
  if ! command -v ansiblesafe &> /dev/null; then
      curl -OL https://github.com/tosin2013/ansiblesafe/releases/download/v${ANSIBLE_SAFE_VERSION}/ansiblesafe-v${ANSIBLE_SAFE_VERSION}-linux-amd64.tar.gz
      tar -zxvf ansiblesafe-v${ANSIBLE_SAFE_VERSION}-linux-amd64.tar.gz
      chmod +x ansiblesafe-linux-amd64 
      sudo mv ansiblesafe-linux-amd64 /usr/local/bin/ansiblesafe
  fi
}

function install_dependencies {
  cd $HOME/kcli-plan-samples
  pip3 install -r profile_generator/requirements.txt
}

function setup_ansible_vault {
  curl -OL https://gist.githubusercontent.com/tosin2013/022841d90216df8617244ab6d6aceaf8/raw/92400b9e459351d204feb67b985c08df6477d7fa/ansible_vault_setup.sh
  chmod +x ansible_vault_setup.sh
  ./ansible_vault_setup.sh
}

function update_profiles_file {
  ansiblesafe -f "${ANSIBLE_VAULT_FILE}" -o 2
  PASSWORD=$(yq eval '.admin_user_password' "${ANSIBLE_VAULT_FILE}")
  python3 profile_generator/profile_generator.py update_yaml rhel9 rhel9/template.yaml --image rhel-baseos-9.1-x86_64-kvm.qcow2 --user $USER --user-password ${PASSWORD}
  python3 profile_generator/profile_generator.py update_yaml fedora37 fedora37/template.yaml --image Fedora-Cloud-Base-37-1.7.x86_64.qcow2  --disk-size 30 --numcpus 4 --memory 8192 --user  $USER  --user-password ${PASSWORD}
  ansiblesafe -f "${ANSIBLE_VAULT_FILE}" -o 1

  sudo mkdir -p "${KCLI_CONFIG_DIR}"
  sudo cp "${PROFILES_FILE}" "${KCLI_CONFIG_FILE}"
  sudo ansiblesafe -f "${KCLI_CONFIG_FILE}" -o 1
}

function create_vm {
  sudo ansiblesafe -f "${KCLI_CONFIG_FILE}" -o 2
  sudo cat "${KCLI_CONFIG_FILE}"
  sudo kcli create vm -p fedora37 testvm
  sudo ansiblesafe -f "${KCLI_CONFIG_FILE}" -o 1
}

check_kcli_plan
install_ansiblesafe
install_dependencies
setup_ansible_vault
update_profiles_file
create_vm
