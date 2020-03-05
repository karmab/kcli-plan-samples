#!/usr/bin/env bash

echo 35.196.103.194 registry.svc.ci.openshift.org >> /etc/hosts
export PULL_SECRET="/root/openshift_pull.json"
export OPENSHIFT_RELEASE_IMAGE={{ openshift_image }}
oc adm release extract --registry-config $PULL_SECRET --command=oc --to /tmp $OPENSHIFT_RELEASE_IMAGE
mv /tmp/oc .
oc adm release extract --registry-config $PULL_SECRET --command=openshift-baremetal-install --to . $OPENSHIFT_RELEASE_IMAGE
