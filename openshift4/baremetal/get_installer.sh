#!/usr/bin/env bash

export PULL_SECRET="/root/openshift_pull.json"
export OPENSHIFT_RELEASE_IMAGE={{ openshift_image }}
oc adm release extract --registry-config $PULL_SECRET --command=oc --to /tmp $OPENSHIFT_RELEASE_IMAGE
mv /tmp/oc .
oc adm release extract --registry-config $PULL_SECRET --command=openshift-baremetal-install --to . $OPENSHIFT_RELEASE_IMAGE
