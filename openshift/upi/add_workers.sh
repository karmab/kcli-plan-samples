#!/bin/bash

BLUE='\033[0;36m'
NC='\033[0m'

. env.sh || true
prefix="${prefix:-karim}"
network="${network:-default}"
masters="${masters:-1}"
workers="${workers:-0}"

old_workers=$( grep workers: $cluster/$prefix.yml | awk '{print $2}')
new_workers=$(( $workers - $old_workers ))
if [ $new_workers -lt 1 ] ; then 
    echo -e "${BLUE}No new workers to add. Leaving...${NC}"
    exit 1
fi

kcli plan -f ocp_temp.yml -P prefix=$prefix -P masters=$masters -P workers=$workers -P network=$network temp_$prefix

all=""

for i in `seq $new_workers $workers` ; do
  if [ "$i" != $workers ] ; then
    all="$all $prefix-worker-$i"
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

sed -i "s/workers: .*/workers: $workers/" $cluster/$prefix.yml
sed -i "s@workers_macs:@$( echo $new_workers_macs | sed 's/ /\n/')/\n&@" $cluster/$prefix.yml

for entry in `echo $new_workers_macs` ; do
  echo "- $entry" >> $cluster/$prefix.yml
done

kcli plan --yes -d  temp_$prefix

kcli plan -f ocp.yml --paramfile $cluster/$prefix.yml $cluster
