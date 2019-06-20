#!/bin/bash

printenv KUBECONFIG >/dev/null 2>&1
if [ "$?" != "0" ] ; then
 echo Please set KUBECONFIG environment variable
 exit 1
fi
echo "$(oc get node -o custom-columns=NAME:.metadata.name,IP:.status.addresses[0].address --no-headers)" | while read node ip ; do
  node=${node%%.*}
  kcli update --ip $ip $node
done
