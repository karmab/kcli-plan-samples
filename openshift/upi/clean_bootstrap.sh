#!/bin/bash

. env.sh || true

cluster="${cluster:-karim}"
cluster="${cluster:-testk}"

openshift-install --dir=${cluster} wait-for bootstrap-complete

kcli ssh root@${cluster}-haproxy "sed -i /bootstrap/d /etc/haproxy/haproxy.cfg"
kcli ssh root@${cluster}-haproxy "systemctl restart haproxy"
kcli delete --yes ${cluster}-bootstrap
