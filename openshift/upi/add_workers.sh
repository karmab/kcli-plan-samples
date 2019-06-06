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

if [ ! -f $cluster/worker.ign.ori ] ; then
helper_ip=$(grep helper_ip $cluster/kcli.yml | awk -F:  '{print $2}' | xargs)
cp $cluster/worker.ign $cluster/worker.ign.ori
curl -kL https://$helper_ip:22623/config/worker -o $cluster/worker.ign
fi

kcli plan -f ocp_temp.yml -P deploy_bootstrap=false -P deploy_helper=false -P cluster=$cluster -P masters=$masters -P workers=$workers -P network=$network temp_$cluster

all=""

for i in `seq $new_workers $workers` ; do
  if [ "$i" != $workers ] ; then
    all="$all $cluster-worker-$i"
  fi
done

total=$(( $(echo $all | wc -w)  * 2 ))
current=0

while [ $current != $total ] ; do
    info=$(kcli info -f ip,nets -v $all | sed 's/.*mac: \(.*\) net:.*/\1/')
    current=$(echo $info | wc -w)
    echo -e "${BLUE}Waiting 5s to gather ips and macs from nodes...${NC}"
    sleep 5
done

entry=$(echo $info | cut -f1 -d" ")

for i in `seq $new_workers $workers` ; do
 if [ "$i" != $workers ] ; then
   entry=$(echo $info | cut -f1 -d" ")
   new_workers_ips="$workers_ips $entry"
   info=$(echo $info | sed "s/$entry //")
   entry=$(echo $info | cut -f1 -d" ")
   new_workers_macs="$workers_macs $entry"
   info=$(echo $info | sed "s/$entry //")
 fi
done

sed -i "s/deploy_bootstrap: .*/deploy_bootstrap: false/" $cluster/kcli.yml
sed -i "s/workers: .*/workers: $workers/" $cluster/kcli.yml
index=$(( $workers - $new_workers ))
for new_workers_ip in $new_workers_ips ; do 
    sed -i "s@workers_macs:@$( echo - $new_workers_ip )\n&@" $cluster/kcli.yml
    for i in `seq 0 $masters` ; do
      if [ "$i" != $masters ] ; then
        kcli ssh root@$cluster-master-$i "echo -e host-record=$cluster-worker-$index.$cluster.$domain,$new_workers_ip,3600 >> /etc/kubernetes/dnsmasq.conf"
        oc delete pod -n openshift-infra dnsmasq-$cluster-master-$i.$cluster.$domain
      fi
    done

    index=$(( $index + 1 ))
done

for entry in `echo $new_workers_macs` ; do
  echo "- $entry" >> $cluster/kcli.yml
done

kcli plan --yes -d  temp_$cluster
kcli plan -f ocp.yml --paramfile $cluster/kcli.yml $cluster
#oc get csr -o name | xargs oc adm certificate approve
