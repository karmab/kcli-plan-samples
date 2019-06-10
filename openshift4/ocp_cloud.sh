#!/bin/bash

. env.sh || true
template="${template:-rhcos-410.8.20190520.1-qemu.qcow2}"
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
tag="${tag:-cnvlab}"
pub_key="${pubkey:-$HOME/.ssh/id_rsa.pub}"
pull_secret="${pullsecret:-openshift_pull.json}"
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

pub_key=`cat $pub_key`
pull_secret=`cat $pull_secret`
mkdir $cluster || exit 1
sed "s%DOMAIN%$domain%" install-config.yaml > $cluster/install-config.yaml
sed -i "s%WORKERS%$workers%" $cluster/install-config.yaml
sed -i "s%MASTERS%$masters%" $cluster/install-config.yaml
sed -i "s%CLUSTER%$cluster%" $cluster/install-config.yaml
sed -i "s%PULLSECRET%$pull_secret%" $cluster/install-config.yaml
sed -i "s%PUBKEY%$pub_key%" $cluster/install-config.yaml

openshift-install --dir $cluster create manifests
cp customisation/* $cluster/openshift
sed -i "s/3/$masters/" $cluster/openshift/99-ingress-controller.yaml
openshift-install --dir $cluster create ignition-configs

echo """cluster: $cluster
numcpus: $numcpus
network: $network
use_br: $use_br
extra_disk: $extra_disk
master_memory: $master_memory
worker_memory: $worker_memory
deploy_bootstrap: true
deploy_alias: true
bootstrap_memory: $bootstrap_memory
disk_size: $disk_size
extra_disk_size: $extra_disk_size
template: $template
domain: $domain
masters: $masters
workers: $workers
tag: $tag""" > $cluster/kcli.yml

kcli vm -p CentOS-7-x86_64-GenericCloud.qcow2 -P reservedns=true -P domain=$cluster.$domain -P tags=[$tag] -P plan=$cluster $cluster-helper
status=""
while [ "$status" != "running" ] ; do
    status=$(kcli info -f status -v $cluster-helper | tr '[:upper:]' '[:lower:]')
    echo -e "${BLUE}Waiting 5s for helper node to be running...${NC}"
    sleep 5
done

kcli ssh root@$cluster-helper "yum -y install httpd ; systemctl start httpd ; systemctl stop firewalld"
kcli scp $cluster/bootstrap.ign root@$cluster-helper:/var/www/html/bootstrap

sed s@https://api-int.$cluster.$domain:22623/config/master@http://$cluster-helper.$cluster.$domain/bootstrap@ $cluster/master.ign > $cluster/bootstrap.ign
kcli plan -f ocp_cloud.yml --paramfile $cluster/kcli.yml $cluster
export KUBECONFIG=$PWD/$cluster/auth/kubeconfig
openshift-install --dir=$cluster wait-for bootstrap-complete || exit 1
api_ip=$(kcli info $cluster-master-0 -f ip -v)
kcli delete --yes $cluster-bootstrap $cluster-helper
kcli dns -n $domain -i $api_ip api.$cluster
kcli dns -n $domain -i $api_ip api-int.$cluster
echo -e "${BLUE}Adding temporary entry for api.$cluster.$domain in your /etc/hosts...${NC}"
sudo sed -i "/api.$cluster.$domain/d" /etc/hosts
sudo sh -c "echo $api_ip api.$cluster.$domain >> /etc/hosts"
if [ "$workers" == "0" ] ; then
 export KUBECONFIG=$PWD/$cluster/auth/kubeconfig
 oc adm taint nodes -l node-role.kubernetes.io/master node-role.kubernetes.io/master:NoSchedule-
fi
openshift-install --dir=$cluster wait-for install-complete
echo -e "${BLUE}Deleting temporary entry for api.$cluster.$domain in your /etc/hosts...${NC}"
sudo sed -i "/api.$cluster.$domain/d" /etc/hosts
