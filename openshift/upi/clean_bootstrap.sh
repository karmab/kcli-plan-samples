#!/bin/bash

. env.sh || true

prefix="${prefix:-karim}"
cluster="${cluster:-testk}"

openshift-install --dir=${cluster} wait-for bootstrap-complete

kcli ssh root@${prefix}-haproxy "sed -i /bootstrap/d /etc/haproxy/haproxy.cfg"
kcli ssh root@${prefix}-haproxy "systemctl restart haproxy"
kcli delete --yes ${prefix}-bootstrap
