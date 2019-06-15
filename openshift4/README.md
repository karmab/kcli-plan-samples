This repo provides a way for deploying ocp4 using an hybrid approach between upi and ipi, and by heavily leveraging kcli.

The initial target ovirt/rhev and libvirt although the approach aims to be independent of the platform.
This was also tested on aws and gcp.

The main features are:

- deploy ocp using minimal infrastructure requirements.
- no need for control over dns and pxe. Those elements are hosted as static pods on the master nodes. For cloud platforms, we use cloud public dns
- Multiple clusters can live on the same network.
- Same procedure for libvirt, ovirt, openstack or kubevirt.
- No need to compile the installer to deploy on libvirt.
- No need to tweak libvirtd.
- The vms can be connected to a real bridge on libvirt.

## requirements

- openshift-install binary needs to be installed from https://mirror.openshift.com/pub/openshift-v4/clients/ocp
- pull secret
- ssh public key
- kcli >= 14.11 (container or pip version if deploying on something else than libvirt)
- direct access to the deployed vms. Use something like this otherwise `sshuttle -r your_hypervisor 192.168.122.0/24 -v`)
- Target platform needs:
  - rhcos image ( *kcli download rhcosootpa* )
  - centos image ( *kcli download centos7* )
- For libvirt, make sure qemu version supports fw_cfg (that means installing qemu-kvm-ev on centos for instance)
- Target platform needs ignition support. 
  - For ovirt/rhv, this either requires ovirt >= 4.3.4 or to install [an additional vdsm hook](https://gerrit.ovirt.org/#/c/100008), along with the custom property *ignitiondata*

## How to Use

### Setting your environment

You can either use default values that can be checked in the parameters section of the file `ocp.yml` or by running `kcli plan -i ocp.yml`

If you want to tweak them, create an *parameters.yml.sample* parameter file similar to [*parameters.yml.sample*](parameters.yml.sample) and edit:

- *cluster* name. Defaults to `testk`
- *domain* name. For cloud platforms, it should point to a domain name you have access too. `Defaults to karmalabs.com`
- *pub_key* location. Defaults to `$HOME/.ssh/id_rsa.pub`
- *pull_secret* location. Defaults to `./openshift_pull.json`
- *template* rhcos template to use (should be an openstack one for ovirt/openstack and qemu for libvirt/kubevirt or on ovirt with ignition hook). You can let this parameter unset if you want the script to check for a rhcos template within the ones available on your client.
- *helper_template* which template to use when deploying temporary vms (defaults to `CentOS-7-x86_64-GenericCloud.qcow2`)
- *masters* number of masters. Defaults to `1`
- *workers* number of workers. Defaults to `1`
- *network*. Defaults to `default`
- *master_memory*. Defaults to `8192Mi`
- *worker_memory*. Defaults to `8192Mi`
- *bootstrap_memory*. Defaults to `4096Mi`
- *numcpus*. Defaults to `4`
- *disk size* default disk size for final nodes. Defaults to `30Gb`
- *extra_disk* whether to create a secondary disk (to use with rook, for instance). Defaults to `false`
- *extra\_disk_size* size for secondary disk. Defaults to `30Gb`
- *use_br* whether to create a bridge on top of the nics of the nodes (useful if planning to deploy kubevirt on top). Defaults to `false`
- *api_ip* the ip to use for api ip. Defaults to `none`, in which case a temporary vm will be launched to gather a free one.

### Deploy

- `./ocp.sh` or `ocp.sh your_parameter_file` if you have created one.

- You will be asked for your sudo password in order to create a /etc/hosts entry for the api vip.

- once that finishes, set the following environment variable in order to use oc commands `export KUBECONFIG=clusters/$cluster/auth/kubeconfig`

- for dns access to your app, you can create a conf file in /etc/NetworkManager/dnsmasq.d with the following line `server=/apps.$cluster.$domain/$api_ip` where api_ip can be found in the last line of your /etc/hosts (and displayed during

### Adding more workers after initial installation

- with default settings, relaunch the plan with `kcli plan -f ocp.yml -P workers=new_number_of_workers -P deploy_bootstrap=false $cluster`
- if using parameterfile, first edit your parameter file and change *workers* parameter and then relaunch the plan with `kcli plan -f ocp.yml --paramfile=your_parameter_file -P deploy_bootstrap=false $cluster`
- wait for certificate requests to appear and approve them with `oc get csr -o name | xargs oc adm certificate approve`

### Cleaning up an install

- Delete all the vms with `kcli plan -d $cluster --yes`
- Delete the generated directory `rm -rf clusters/$cluster`

## architecture

### On ovirt/libvirt

We deploy :

- an arbitrary number of masters.
- an arbitrary number of workers.
- a bootstrap node removed during the install.

We first generate all the ignition files needed for the install.

Then, if no api ip has been specified, we do a temporary deployment of a single vm using a centos7 template to gather a free ip

With all this information, a kcli parameter file is created and stored in the same directory than the openshift artifacts for the given cluster.

We then launch the deployment

Keepalived and Coredns with mdns are created on the fly on the bootstrap and master nodes as static pods. Initially, the api vip runs on the bootstrap node.

Nginx is created as static pod on the bootstrap node to serve as a http only web server for some additional ignition files needed on the nodes and which can't get injected (they are generated on the bootstrap node).

Haproxy is created as static pod on the master nodes to load balance traffic to the routers. When there are no workers, routers are instead scheduled on the master nodes and the haproxy static pod isn't created, so routers are simply accessed through the vip without load balancing in this case.

Once bootstrap step is finished, the corresponding vm gets deleted, causing keepalived to migrate the api vip to one of the masters.

Also note that for bootstrap, masters and workers nodes, we merge the ignition data generated by the openshift installer with the ones generated by kcli, in particular we prepend dns server on those nodes to point to our keepalived vip.

### On aws/gcp

On those platform, we can't host a private vip on the nodes, so we rely exclusively on dns (with no load balancing at the moment)

For aws, you can use the rhcos-* ami images

For gcp, you will need to get the rhcos image, move it to a google bucket and import the image (this will soon be automated in kcli download)

An extra temporary node is deployed to serve ignition data to the bootstrap node, as those platforms use userdata field to pass ignition, and the bootstrap has too many characters.

Additionally, we automatically create the following dns records:

- api.$cluster.$domain initially pointing to the public ip of the bootstrap node, and later on changed to point to the public ip of the first master node
- *.apps.$cluster.$domain pointing to the public ip of the first master node ( or the first worker node if present)
- etcd-$num and default fqdn entries pointing to the private ip for the corresponding masters
- the proper srv dns entries.
