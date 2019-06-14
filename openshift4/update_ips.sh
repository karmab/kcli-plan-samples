#!/bin/bash

echo "$(oc get node -o custom-columns=NAME:.metadata.name,IP:.status.addresses[0].address --no-headers)" | while read node ip ; do
  node=${node%%.*}
  kcli update --ip $ip $node
done
