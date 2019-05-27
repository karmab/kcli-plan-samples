#!/bin/bash

. env.sh || true
prefix="${prefix:-karim}"
numcpus="${numcpus:-4}"
network="${network:-default}"
use_br="${use_br:-false}"
extra_disk="${extra_disk:-false}"
master_memory="${master_memory:-8192}"
worker_memory="${worker_memory:-8192}"
bootstrap_memory="${bootstrap_memory:-4096}"
haproxy_memory="${haproxy_memory:-2048}"
haproxy_bootstrap="${haproxy_bootstrap:-false}"
disk_size="${disk_size:-30}"
extra_disk_size="${extra_disk_size:-10}"
template="${template:-rhcos-410.8.20190520.1-qemu.qcow2}"
haproxy_template="${haproxy_template:-CentOS-7-x86_64-GenericCloud.qcow2}"
cluster="${cluster:-testk}"
domain="${domain:-karmalabs.com}"
masters="${masters:-1}"
workers="${workers:-0}"

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

kcli plan -f ocp_temp.yml -P prefix=$prefix -P masters=$masters -P workers=$workers -P network=$network temp_$prefix

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
BLUE='\033[0;36m'
NC='\033[0m'

while [ $current != $total ] ; do
    info=$(kcli info -f ip,nets -v $all | sed 's/.*mac: \(.*\) net:.*/\1/')
    current=$(echo $info | wc -w)
    echo -e "${BLUE}Waiting 5s to gather ips and macs from nodes...${NC}"
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
numcpus: $numcpus
network: $network
use_br: $use_br
extra_disk: $extra_disk
master_memory: $master_memory
worker_memory: $worker_memory
deploy_bootstrap: true
bootstrap_memory: $bootstrap_memory
haproxy_memory: $haproxy_memory
haproxy_bootstrap: $haproxy_bootstrap
disk_size: $disk_size
extra_disk_size: $extra_disk_size
template: $template
haproxy_template: $haproxy_template
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
sed -i s@https://api-int.$cluster.$domain:22623/config@http://$haproxy_ip:8080@ $cluster/master.ign $cluster/worker.ign
if [ "$haproxy_bootstrap" == "true" ] ; then
 mv $cluster/bootstrap.ign $cluster/bootstrap.ign.ori
 cp $cluster/master.ign $cluster/bootstrap.ign
 sed -i s@$haproxy_ip:8080/master@$haproxy_ip:8081/bootstrap@ $cluster/bootstrap.ign
fi
kcli plan -f ocp.yml --paramfile $cluster/$prefix.yml $cluster
export KUBECONFIG=$PWD/$cluster/auth/kubeconfig
sudo sed -i '/api.$cluster.$domain/d' /etc/hosts
sudo sh -c "echo $haproxy_ip api.$cluster.$domain>> /etc/hosts"
# openshift-install --dir=$cluster wait-for install-complete
# oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
