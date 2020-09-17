chmod 600 /root/.ssh/id_rsa
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /root/rhcos-live.x86_64.iso {{ config_user | default('root') }}@{{ config_host}}:{{ iso_path }}
