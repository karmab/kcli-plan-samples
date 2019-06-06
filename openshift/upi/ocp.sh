#!/bin/bash

. env.sh || true
template="${template:-rhcos-410.8.20190520.1-qemu.qcow2}"
helper_template="${helper_template:-CentOS-7-x86_64-GenericCloud.qcow2}"
cluster="${cluster:-testk}"
domain="${domain:-karmalabs.com}"
numcpus="${numcpus:-4}"
network="${network:-default}"
use_br="${use_br:-false}"
extra_disk="${extra_disk:-false}"
master_memory="${master_memory:-8192}"
worker_memory="${worker_memory:-8192}"
bootstrap_memory="${bootstrap_memory:-4096}"
disk_size="${disk_size:-30}"
extra_disk_size="${extra_disk_size:-10}"
masters="${masters:-1}"
workers="${workers:-0}"
pubkey="${pubkey:-$HOME/.ssh/id_rsa.pub}"
pullsecret="${pullsecret:-openshift_pull.json}"
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

INSTALLER=$(which openshift-install 2>/dev/null)
if  [ "$INSTALLER" == "" ] ; then
 echo -e "${RED}Missing openshift-install binary. Get it at https://mirror.openshift.com/pub/openshift-v4/clients/ocp${NC}"
 exit 1
fi
OC=$(which oc 2>/dev/null)
if  [ "$OC" == "" ] ; then
 echo -e "${RED}Missing oc binary. Get it at https://mirror.openshift.com/pub/openshift-v4/clients/ocp${NC}"
 exit 1
fi

pubkey=`cat $pubkey`
pullsecret=`cat $pullsecret`
mkdir $cluster || exit 1
sed "s%DOMAIN%$domain%" install-config.yaml > $cluster/install-config.yaml
sed -i "s%WORKERS%$workers%" $cluster/install-config.yaml
sed -i "s%MASTERS%$masters%" $cluster/install-config.yaml
sed -i "s%CLUSTER%$cluster%" $cluster/install-config.yaml
sed -i "s%PULLSECRET%$pullsecret%" $cluster/install-config.yaml
sed -i "s%PUBKEY%$pubkey%" $cluster/install-config.yaml

openshift-install --dir $cluster create manifests
cp customisation/* $cluster/openshift
sed -i "s/3/$masters/" $cluster/openshift/99-ingress-controller.yaml
openshift-install --dir $cluster create ignition-configs

kcli plan -f ocp_temp.yml -P template=$helper_template -P cluster=$cluster -P masters=$masters -P workers=$workers -P network=$network temp_$cluster

all="$cluster-helper $cluster-bootstrap"
for i in `seq 0 $masters` ; do 
 if [ "$i" != $masters ] ; then
   all="$all $cluster-master-$i"
 fi
done
  for i in `seq 0 $workers` ; do 
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
helper_ip=$entry
info=$(echo $info | sed "s/$entry //")
entry=$(echo $info | cut -f1 -d" ")
helper_mac=$entry
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

echo """cluster: $cluster
numcpus: $numcpus
network: $network
use_br: $use_br
extra_disk: $extra_disk
master_memory: $master_memory
worker_memory: $worker_memory
deploy_bootstrap: true
bootstrap_memory: $bootstrap_memory
disk_size: $disk_size
extra_disk_size: $extra_disk_size
template: $template
helper_template: $helper_template
domain: $domain
masters: $masters
workers: $workers
helper_ip: $helper_ip
helper_mac: $helper_mac
bootstrap_ip: $bootstrap_ip
bootstrap_mac: $bootstrap_mac""" > $cluster/kcli.yml

echo "masters_ips:" >> $cluster/kcli.yml
for entry in `echo $masters_ips` ; do 
  echo "- $entry" >> $cluster/kcli.yml
done
echo "masters_macs:" >> $cluster/kcli.yml
for entry in `echo $masters_macs` ; do 
  echo "- $entry" >> $cluster/kcli.yml
done
echo "workers_ips:" >> $cluster/kcli.yml
for entry in `echo $workers_ips` ; do 
  echo "- $entry" >> $cluster/kcli.yml
done
echo "workers_macs:" >> $cluster/kcli.yml
for entry in `echo $workers_macs` ; do 
  echo "- $entry" >> $cluster/kcli.yml
done

kcli plan --yes -d  temp_$cluster
sed -i s@https://api-int.$cluster.$domain:22623/config@http://$helper_ip:8080@ $cluster/master.ign $cluster/worker.ign
kcli plan -f ocp.yml --paramfile $cluster/kcli.yml $cluster
export KUBECONFIG=$PWD/$cluster/auth/kubeconfig
echo -e "${BLUE}Adding entry for api.$cluster.$domain in your /etc/hosts...${NC}"
sudo sed -i "/api.$cluster.$domain/d" /etc/hosts
sudo sh -c "echo $helper_ip api.$cluster.$domain console-openshift-console.apps.$cluster.$domain oauth-openshift.apps.$cluster.$domain >> /etc/hosts"
#sshuttle -r your_hypervisor $helper_ip/32 -v
openshift-install --dir=$cluster wait-for bootstrap-complete
kcli delete --yes $cluster-bootstrap
#oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
#oc patch --namespace=openshift-ingress-operator --patch='{"spec": {"replicas": 1}}' --type=merge ingresscontroller/default
if [ "$workers" == "0" ] ; then
oc adm taint nodes -l node-role.kubernetes.io/master node-role.kubernetes.io/master:NoSchedule-
fi
openshift-install --dir=$cluster wait-for install-complete
