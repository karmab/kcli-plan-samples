#!/bin/bash
PREFIX=karim
MASTERS=1
for i in `seq 1 $MASTERS` ; do
kcli vm -p CentOS-7-x86_64-GenericCloud.qcow2 temp_$PREFIX_$i
while [ "$ip" == "" ] ; do 
 read ip mac <<< $(kcli info -f ip,nets -v temp_$PREFIX_$i | sed 's/.*mac: \(.*\) net:.*/\1/')
done
kcli delete --yes temp_$PREFIX_$i
done
kcli plan -f kcli_ocp.yml --paramfile ${PREFIX}.yml
