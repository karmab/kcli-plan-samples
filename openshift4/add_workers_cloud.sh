#!/bin/bash

RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

. env.sh || true
cluster="${cluster:-testk}"
network="${network:-default}"
masters="${masters:-1}"
workers="${workers:-0}"
domain="${domain:-karmalabs.com}"

old_workers=$( grep workers: $cluster/kcli.yml | awk '{print $2}')
new_workers=$(( $workers - $old_workers ))
if [ $new_workers -lt 1 ] ; then 
    echo -e "${RED}No new workers to add. Leaving...${NC}"
    exit 1
fi

sed -i "s/deploy_bootstrap: .*/deploy_bootstrap: false/" $cluster/kcli.yml
sed -i "s/deploy_alias: .*/deploy_alias: false/" $cluster/kcli.yml
kcli plan -f ocp_cloud.yml --paramfile $cluster/kcli.yml $cluster
#oc get csr -o name | xargs oc adm certificate approve
