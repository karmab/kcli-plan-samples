#!/usr/bin/env bash

#set -euo pipefail

export HOME=/root
export KUBECONFIG=/root/ocp/auth/kubeconfig
export OS_CLOUD=metal3-bootstrap
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=registry.svc.ci.openshift.org/ocp/release:{{ tag }}
mkdir -p ocp/openshift
{% if config_host is defined %}
TESTLIBVIRT=$(grep libvirtURI /root/install-config.yaml)
if [ "$TESTLIBVIRT" == "" ] ; then
  SPACES=$(grep apiVIP /root/install-config.yaml | sed 's/apiVIP.*//' | sed 's/ /\\ /'g)
  sed -i "/hosts/i${SPACES}libvirtURI: qemu+ssh://root@{{ config_host }}/system" /root/install-config.yaml
fi
{% endif %}
PROVISIONING_IP=$(grep libvirtURI install-config.yaml | awk -F'/' '{ print $3 }' | awk -F'@' '{ print $2 }')
ssh-keyscan -H $PROVISIONING_IP >> ~/.ssh/known_hosts
echo -e "Host=*\nStrictHostKeyChecking=no\n" > .ssh/config
TESTPULLSECRET=$(grep pullSecret /root/install-config.yaml)
if [ "$TESTPULLSECRET" == "" ] ; then
    PULLSECRET=$(cat $HOME/openshift_pull.json | tr -d [:space:])
    echo -e "pullSecret: |\n  $PULLSECRET" >> /root/install-config.yaml
fi
TESTSSHKEY=$(grep sshKey /root/install-config.yaml)
if [ "$TESTSSHKEY" == "" ] ; then
    SSHKEY=$(cat $HOME/.ssh/id_?sa.pub)
    echo -e "sshKey: |\n  $SSHKEY" >> /root/install-config.yaml
fi

{% if virtual %}
bash /root/virtual.sh
{% endif %}
PYTHON="python"
which python3 >/dev/null 2>&1 && PYTHON="python3"
$PYTHON /root/ipmi.py off
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
