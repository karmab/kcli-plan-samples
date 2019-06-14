#!/bin/bash

printenv KUBECONFIG || ( echo Please set KUBECONFIG environment variable && exit 1 )
echo "$(oc get node -o custom-columns=NAME:.metadata.name,IP:.status.addresses[0].address --no-headers)" | while read node ip ; do
  node=${node%%.*}
  kcli update --ip $ip $node
done
