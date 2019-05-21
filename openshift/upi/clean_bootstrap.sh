#!/bin/bash
prefix=karim
masters=1
cluster=testk
domain=karmalabs.com
workers=0

kcli ssh root@$prefix-haproxy "sed -i /bootstrap/d /etc/haproxy/haproxy.cfg"
kcli ssh root@$prefix-haproxy "systemctl restart haproxy"
kcli delete --yes $prefix-bootstrap
