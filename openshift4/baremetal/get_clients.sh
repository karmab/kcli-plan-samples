#!/usr/bin/env bash

curl --silent https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.4/linux/oc.tar.gz > oc.tar.gz
tar zxf oc.tar.gz
rm -rf oc.tar.gz
chmod +x oc

curl -Ls https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > jq
chmod u+x jq
curl -Ls https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 > yq
chmod u+x yq
