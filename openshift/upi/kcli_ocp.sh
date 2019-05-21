#!/bin/bash
masters=1
workers=0
cluster=testk
domain=karmalabs.com
prefix=karim

pubkey=`cat ~/.ssh/id_rsa.pub`
pullsecret=`cat openshift_pull.json`
mkdir $cluster || exit 1
sed "s%DOMAIN%$domain%" install-config.yaml > $cluster/install-config.yaml
sed -i "s%WORKERS%$workers%" $cluster/install-config.yaml
sed -i "s%MASTERS%$masters%" $cluster/install-config.yaml
sed -i "s%CLUSTER%$cluster%" $cluster/install-config.yaml
sed -i "s%PULLSECRET%$pullsecret%" $cluster/install-config.yaml
sed -i "s%PUBKEY%$pubkey%" $cluster/install-config.yaml
openshift-install --dir $cluster create ignition-configs

kcli plan -f kcli_ocp_temp.yml -P prefix=$prefix -P masters=$masters -P workers=$workers temp_$prefix

all="$prefix-haproxy $prefix-bootstrap"
for i in `seq 0 $masters` ; do 
 if [ "$i" != $masters ] ; then
   all="$all $prefix-master-$i"
 fi
done
  for i in `seq 0 $workers` ; do 
    if [ "$i" != $workers ] ; then
      all="$all $prefix-worker-$i"
    fi
  done

total=$(( $(echo $all | wc -w)  * 2 ))
current=0

while [ $current != $total ] ; do
    info=$(kcli info -f ip,nets -v $all | sed 's/.*mac: \(.*\) net:.*/\1/')
    current=$(echo $info | wc -w)
    echo "Waiting 5s to gather ips and macs from nodes..."
    sleep 5
done

entry=$(echo $info | cut -f1 -d" ")
haproxy_ip=$entry
info=$(echo $info | sed "s/$entry //")
entry=$(echo $info | cut -f1 -d" ")
haproxy_mac=$entry
info=$(echo $info | sed "s/$entry //")
entry=$(echo $info | cut -f1 -d" ")
bootstrap_ip=$entry
info=$(echo $info | sed "s/$entry //")
entry=$(echo $info | cut -f1 -d" ")
bootstrap_mac=$entry
info=$(echo $info | sed "s/$entry //")

for i in `seq 0 $masters` ; do 
 if [ "$i" != $masters ] ; then
   entry=$(echo $info | cut -f1 -d" ")
   masters_ips="$masters_ips $entry"
   info=$(echo $info | sed "s/$entry //")
   entry=$(echo $info | cut -f1 -d" ")
   masters_macs="$masters_macs $entry"
   info=$(echo $info | sed "s/$entry //")
 fi
done

for i in `seq 0 $workers` ; do 
 if [ "$i" != $workers ] ; then
   entry=$(echo $info | cut -f1 -d" ")
   workers_ips="$workers_ips $entry"
   info=$(echo $info | sed "s/$entry //")
   entry=$(echo $info | cut -f1 -d" ")
   workers_macs="$workers_macs $entry"
   info=$(echo $info | sed "s/$entry //")
 fi
done

echo """prefix: $prefix
cluster: $cluster
domain: $domain
masters: $masters
workers: $workers
haproxy_ip: $haproxy_ip
haproxy_mac: $haproxy_mac
bootstrap_ip: $bootstrap_ip
bootstrap_mac: $bootstrap_mac""" > $cluster/$prefix.yml

echo "masters_ips:" >> $cluster/$prefix.yml
for entry in `echo $masters_ips` ; do 
  echo "- $entry" >> $cluster/$prefix.yml
done
echo "masters_macs:" >> $cluster/$prefix.yml
for entry in `echo $masters_macs` ; do 
  echo "- $entry" >> $cluster/$prefix.yml
done
echo "workers_ips:" >> $cluster/$prefix.yml
for entry in `echo $workers_ips` ; do 
  echo "- $entry" >> $cluster/$prefix.yml
done
echo "workers_macs:" >> $cluster/$prefix.yml
for entry in `echo $workers_macs` ; do 
  echo "- $entry" >> $cluster/$prefix.yml
done

kcli plan --yes -d  temp_$prefix
sed -i s@https://api-int.$cluster.$domain::22623/config@http://$haproxy_ip:8080@ $cluster/master.ign $cluster/worker.ign
kcli plan -f kcli_ocp.yml --paramfile $cluster/$prefix.yml $prefix
