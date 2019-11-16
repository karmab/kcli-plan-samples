#!/bin/bash
export KUBECONFIG=/root/{{ cluster }}/auth/kubeconfig
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=registry.svc.ci.openshift.org/ocp/release:{{ tag }}
openshift-baremetal-install --dir {{ cluster }} --log-level debug create cluster
