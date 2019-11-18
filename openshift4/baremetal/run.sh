python ipmi.py off
export HOME=/root
export PATH=/root:$PATH
export KUBECONFIG=/root/ocp/auth/kubeconfig
export OS_CLOUD=metal3-bootstrap
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=registry.svc.ci.openshift.org/ocp/release:{{ tag }}
mkdir -p ocp/openshift
cp install-config.yaml ocp
cp metal3-config.yaml ocp/openshift
openshift-baremetal-install --dir ocp --log-level debug create cluster