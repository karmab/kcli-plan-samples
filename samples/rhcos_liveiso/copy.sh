chmod 600 /root/.ssh/id_rsa
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null klive.x86_64.iso {{ config_user | default('root') }}@{{ config_host}}:{{ iso_path }}
