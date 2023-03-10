export ANSIBLE_VAULT_FILE="$HOME/quibinode_navigator/inventories/localhost/group_vars/control/vault.yml"
ansiblesafe -f "${ANSIBLE_VAULT_FILE}" -o 2
PASSWORD=$(yq eval '.admin_user_password' "${ANSIBLE_VAULT_FILE}")
sudo python3 profile_generator/profile_generator.py update_yaml ansible-aap ansible-aap/plan-template.yml --image rhel-baseos-9.1-x86_64-kvm.qcow2 --user $USER --user-password ${PASSWORD}
sudo kcli create plan -f ansible-aap/plan.yml