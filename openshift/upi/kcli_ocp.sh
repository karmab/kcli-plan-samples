#!/bin/bash
prefix=karim
masters=1
domain=karmalabs.com

workers=0
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
    echo "Waiting to gather ips and macs from nodes"
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
domain: $domain
masters: $masters
workers: $workers
haproxy_ip: $haproxy_ip
haproxy_mac: $haproxy_mac
bootstrap_ip: $bootstrap_ip
bootstrap_mac: $bootstrap_mac""" > $prefix.yml

echo "masters_ips:" >> $prefix.yml
for entry in `echo $masters_ips` ; do 
  echo "- $entry" >> $prefix.yml
done
echo "masters_macs:" >> $prefix.yml
for entry in `echo $masters_macs` ; do 
  echo "- $entry" >> $prefix.yml
done
echo "workers_ips:" >> $prefix.yml
for entry in `echo $workers_ips` ; do 
  echo "- $entry" >> $prefix.yml
done
echo "workers_macs:" >> $prefix.yml
for entry in `echo $workers_macs` ; do 
  echo "- $entry" >> $prefix.yml
done

kcli plan --yes -d  temp_$prefix
kcli plan -f kcli_ocp.yml --paramfile $prefix.yml $prefix
