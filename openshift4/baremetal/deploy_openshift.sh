#!/usr/bin/env bash

#set -euo pipefail

export HOME=/root
export KUBECONFIG=/root/ocp/auth/kubeconfig
export OS_CLOUD=metal3-bootstrap
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE={{ openshift_image}}
bash /root/clean.sh
mkdir -p ocp/openshift
python3 /root/ipmi.py off
cp install-config.yaml ocp
openshift-baremetal-install --dir ocp --log-level debug create manifests
cp metal3-config.yaml ocp/openshift/99_metal3-config.yaml
ls manifests/*.yaml >/dev/null 2>&1 && cp manifests/*.yaml ocp/openshift/
openshift-baremetal-install --dir ocp --log-level debug create cluster || true
openshift-baremetal-install --dir ocp --log-level debug wait-for install-complete || openshift-baremetal-install --dir ocp --log-level debug wait-for install-complete
{% if wait_workers %}
TOTAL_WORKERS=$(grep 'role: worker' /root/install-config.yaml | wc -l)
if [ "$TOTAL_WORKERS" -gt "0" ] ; then
 until [ "$CURRENT_WORKERS" == "$TOTAL_WORKERS" ] ; do
  CURRENT_WORKERS=$(oc get nodes --selector='node-role.kubernetes.io/worker' -o name | wc -l)
  logger "Waiting for workers to all show up..."
  sleep 5
done
fi
{% endif %}
