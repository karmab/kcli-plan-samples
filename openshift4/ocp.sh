#!/bin/bash

# set some printing colors
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

[ -f env.sh ] && shopt -s expand_aliases  && source env.sh

which kcli >/dev/null 2>&1
BIN="$?"
alias kcli >/dev/null 2>&1
ALIAS="$?"

if [ "$BIN" != "0" ] && [ "$ALIAS" != "0" ]; then
  engine="docker"
  which podman >/dev/null 2>&1 && engine="podman"
  VOLUMES=""
  [ -d /var/lib/libvirt/images ] && [ -d /var/run/libvirt:/var/run/libvirt ] && VOLUMES="-v /var/lib/libvirt/images:/var/lib/libvirt/images -v /var/run/libvirt:/var/run/libvirt"
  alias kcli="$engine run -it --rm --security-opt label=disable -v $HOME/.kcli:/root/.kcli $VOLUMES -v $PWD:/workdir karmab/kcli"
  echo -e "${BLUE}Using $(alias kcli)${NC}"
fi

shopt -s expand_aliases
kcli -v >/dev/null 2>&1
if [ "$?" != "0" ] ; then
  echo -e "${RED}kcli not found. Install it from copr karmab/kcli or pull container${NC}"
  exit 1
fi

client=$(kcli list --clients | grep X | awk -F'|' '{print $2}')
echo -e "${BLUE}Deploying on client $client${NC}"
kcli="kcli -C $client"
#[ -f env.sh ] && kcli="eval kcli2 -C $client"
#[ -f env.sh ] && kcli=$(alias kcli2 | awk -F "'" '{print $2}')" -C $client"
alias kcli >/dev/null 2>&1 && kcli=$(alias kcli | awk -F "'" '{print $2}')" -C $client"

if [ "$#" == '1' ]; then
  envname="$1"
  paramfile="$1"
  if [ ! -f $paramfile ]; then
    echo -e "${RED}Specified parameter file $paramfile doesn't exist.Leaving...${NC}"
    exit 1
  else
    while read line ; do export $(echo "$line" | cut -d: -f1 | xargs)=$(echo "$line" | cut -d: -f2 | xargs) ; done < $paramfile
  fi
  kcliplan="$kcli plan --paramfile=$paramfile"
else
  envname="testk"
  kcliplan="$kcli plan"
fi

cluster="${cluster:-$envname}"
helper_template="${helper_template:-CentOS-7-x86_64-GenericCloud.qcow2}"
helper_sleep="${helper_sleep:-15}"
default_template=$(grep -m1 template: ocp.yml | awk -F: '{print $2}' | xargs)
template="${template:-$default_template}"
api_ip="${api_ip:-}"
public_api_ip="${public_api_ip:-}"
bootstrap_api_ip="${bootstrap_api_ip:-}"
domain="${domain:-karmalabs.com}"
network="${network:-default}"
masters="${masters:-1}"
workers="${workers:-0}"
tag="${tag:-cnvlab}"
pub_key="${pubkey:-$HOME/.ssh/id_rsa.pub}"
pull_secret="${pull_secret:-openshift_pull.json}"
force="${force:-false}"

clusterdir=clusters/$cluster
export KUBECONFIG=$PWD/$clusterdir/auth/kubeconfig
INSTALLER=$(which openshift-install 2>/dev/null)
if  [ "$INSTALLER" == "" ]; then
 echo -e "${RED}Missing openshift-install binary. Get it at https://mirror.openshift.com/pub/openshift-v4/clients/ocp${NC}"
 exit 1
fi
OC=$(which oc 2>/dev/null)
if  [ "$OC" == "" ]; then
 echo -e "${RED}Missing oc binary. Get it at https://mirror.openshift.com/pub/openshift-v4/clients/ocp${NC}"
 exit 1
fi

[ "$force" == "false" ] && [ -d $clusterdir ] && echo -e "${RED}Please Remove existing $clusterdir first${NC}..." && exit 1
mkdir -p $clusterdir || true

shorttemplate=$(echo $template | sed 's/-\(openstack\|qemu\).qcow2//')
echo -e "${BLUE}Using template $template...${NC}"
$kcli list --templates | grep -q $shorttemplate 
if [ "$?" != "0" ]; then
 echo -e "${RED}Missing $template. Indicate correct template in your parameters file...${NC}"
 exit 1
fi

pub_key=`cat $pub_key`
pull_secret=`cat $pull_secret | tr -d '\n'`
sed "s%DOMAIN%$domain%" install-config.yaml > $clusterdir/install-config.yaml
sed -i "s%WORKERS%$workers%" $clusterdir/install-config.yaml
sed -i "s%MASTERS%$masters%" $clusterdir/install-config.yaml
sed -i "s%CLUSTER%$cluster%" $clusterdir/install-config.yaml
sed -i "s%PULLSECRET%$pull_secret%" $clusterdir/install-config.yaml
sed -i "s%PUBKEY%$pub_key%" $clusterdir/install-config.yaml

openshift-install --dir=$clusterdir create manifests
cp customisation/* $clusterdir/openshift
sed -i "s/3/$masters/" $clusterdir/openshift/99-ingress-controller.yaml
openshift-install --dir=$clusterdir create ignition-configs

platform=$($kcli list --clients | grep X | awk -F'|' '{print $3}' | xargs | sed 's/kvm/libvirt/')

if [ "$platform" == "openstack" ]; then
  if [ -z "$api_ip" ] || [ -z "$public_api_ip" ]; then
    echo -e "${RED}You need to define both api_ip and public_api_ip in your parameter file${NC}"
    exit 1
  fi
fi

if [[ "$platform" == *virt* ]] || [[ "$platform" == *openstack* ]]; then
  if [ -z "$api_ip" ]; then
    # we deploy a temp vm to grab an ip for the api, if not predefined
    $kcli vm -p $helper_template -P plan=$cluster -P nets=[$network] $cluster-helper
    api_ip=""
    while [ "$api_ip" == "" ] ; do
      api_ip=$($kcli info -f ip -v $cluster-helper)
      echo -e "${BLUE}Waiting 5s to retrieve api ip from helper node...${NC}"
      sleep 5
    done
    $kcli delete --yes $cluster-helper
    echo -e "${BLUE}Using $api_ip for api vip ...${NC}"
    echo -e "${BLUE}Adding entry for api.$cluster.$domain in your /etc/hosts...${NC}"
    if [[ "$platform" == *openstack* ]]; then
        host_ip=$public_api_ip
    else
        host_ip=$api_ip
    fi
    sudo sed -i "/api.$cluster.$domain/d" /etc/hosts
    sudo sh -c "echo $host_ip api.$cluster.$domain console-openshift-console.apps.$cluster.$domain oauth-openshift.apps.$cluster.$domain >> /etc/hosts"
    echo "api_ip: $api_ip" >> $paramfile
  else
    if [[ "$platform" == *openstack* ]]; then
        host_ip=$public_api_ip
    else
        host_ip=$api_ip
    fi
    echo -e "${BLUE}Using $host_ip for api vip ...${NC}"
    grep -q "$host_ip api.$cluster.$domain" /etc/hosts || sudo sh -c "echo $host_ip api.$cluster.$domain console-openshift-console.apps.$cluster.$domain oauth-openshift.apps.$cluster.$domain >> /etc/hosts"
  fi
  if [ "$platform" == "kubevirt" ] || [ "$platform" == "openstack" ]; then
    # bootstrap ignition is too big for kubevirt/openstack so we serve it from a dedicated temporary node
    if [ "$platform" == "kubevirt" ]; then
      helper_template="kubevirt/fedora-cloud-container-disk-demo"
      helper_parameters=""
      iptype="ip"
    else
      helper_template="CentOS-7-x86_64-GenericCloud.qcow2"
      helper_parameters="-P flavor=m1.medium"
      iptype="privateip"
    fi
    $kcli vm -p $helper_template -P plan=$cluster -P nets=[$network] $helper_parameters $cluster-bootstrap-helper
    while [ "$bootstrap_api_ip" == "" ] ; do
      bootstrap_api_ip=$($kcli info -f $iptype -v $cluster-bootstrap-helper)
      echo -e "${BLUE}Waiting 5s for bootstrap helper node to be running...${NC}"
      sleep 5
    done
    sleep $helper_sleep
    $kcli ssh root@$cluster-bootstrap-helper "yum -y install httpd ; systemctl start httpd"
    $kcli scp $clusterdir/bootstrap.ign root@$cluster-bootstrap-helper:/var/www/html/bootstrap
    sed "s@https://api-int.$cluster.$domain:22623/config/master@http://$bootstrap_api_ip/bootstrap@" $clusterdir/master.ign > $clusterdir/bootstrap.ign
  fi
  sed -i "s@https://api-int.$cluster.$domain:22623/config@http://$api_ip:8080@" $clusterdir/master.ign $clusterdir/worker.ign
fi

if [[ "$platform" != *virt* ]] && [[ "$platform" != *openstack* ]]; then
  # bootstrap ignition is too big for cloud platforms to handle so we serve it from a dedicated temporary vm
  $kcli vm -p $helper_template -P reservedns=true -P domain=$cluster.$domain -P tags=[$tag] -P plan=$cluster -P nets=[$network] $cluster-bootstrap-helper
  status=""
  while [ "$status" != "running" ] ; do
      status=$($kcli info -f status -v $cluster-bootstrap-helper | tr '[:upper:]' '[:lower:]')
      echo -e "${BLUE}Waiting 5s for bootstrap helper node to be running...${NC}"
      sleep 5
  done
  $kcli ssh root@$cluster-bootstrap-helper "yum -y install httpd ; systemctl start httpd ; systemctl stop firewalld"
  $kcli scp $cluster/bootstrap.ign root@$cluster-bootstrap-helper:/var/www/html/bootstrap
  sed s@https://api-int.$cluster.$domain:22623/config/master@http://$cluster-bootstrap-helper.$cluster.$domain/bootstrap@ $clusterdir/master.ign > $clusterdir/bootstrap.ign
fi

if [[ "$platform" == *virt* ]] || [[ "$platform" == *openstack* ]]; then
  $kcliplan -f ocp.yml $cluster
  openshift-install --dir=$clusterdir wait-for bootstrap-complete || exit 1
  todelete="$cluster-bootstrap"
  [ "$platform" == "kubevirt" ] && todelete="$todelete $cluster-bootstrap-helper"
  [[ "$platform" != *"virt"* ]] && todelete="$todelete $cluster-bootstrap-helper"
  $kcli delete --yes $todelete
else
  $kcliplan -f ocp_cloud.yml $cluster
  openshift-install --dir=$clusterdir wait-for bootstrap-complete || exit 1
  api_ip=$($kcli info $cluster-master-0 -f ip -v)
  $kcli delete --yes $cluster-bootstrap $cluster-helper
  $kcli dns -n $domain -i $api_ip api.$cluster
  $kcli dns -n $domain -i $api_ip api-int.$cluster
  echo -e "${BLUE}Adding temporary entry for api.$cluster.$domain in your /etc/hosts...${NC}"
  sudo sed -i "/api.$cluster.$domain/d" /etc/hosts
  sudo sh -c "echo $api_ip api.$cluster.$domain >> /etc/hosts"
fi

if [[ "$platform" == *virt* ]]; then
  cp $clusterdir/worker.ign $clusterdir/worker.ign.ori
  curl --silent -kL https://api.$cluster.$domain:22623/config/worker -o $clusterdir/worker.ign
fi

if [ "$workers" -lt "1" ]; then
 oc adm taint nodes -l node-role.kubernetes.io/master node-role.kubernetes.io/master:NoSchedule-
fi
openshift-install --dir=$clusterdir wait-for install-complete || openshift-install --dir=$clusterdir wait-for install-complete

if [[ "$platform" != *virt* ]]; then
  echo -e "${BLUE}Deleting temporary entry for api.$cluster.$domain in your /etc/hosts...${NC}"
  sudo sed -i "/api.$cluster.$domain/d" /etc/hosts
fi
