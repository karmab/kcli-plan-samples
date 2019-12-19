export PULL_SECRET="/root/openshift_pull.json"
export OPENSHIFT_RELEASE_IMAGE=registry.svc.ci.openshift.org/ocp/release:{{ tag }}
oc adm release extract --registry-config $PULL_SECRET --command=openshift-baremetal-install --to . $OPENSHIFT_RELEASE_IMAGE
