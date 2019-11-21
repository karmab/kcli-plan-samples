export PULL_SECRET="openshift_pull.json"
export OPENSHIFT_RELEASE_IMAGE=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt | grep 'Pull From: quay.io' | awk -F ' ' '{print $3}' | xargs)
oc adm release extract --registry-config $PULL_SECRET --command=openshift-baremetal-install --to . $OPENSHIFT_RELEASE_IMAGE
