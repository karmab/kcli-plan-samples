Plans to deploy Ceph clusters:


**Using Ceph Ansible:**
https://docs.ceph.com/ceph-ansible/master/

```
# kcli create plan -f upstream.yml
```

**Using Cephadm:**
https://docs.ceph.com/docs/master/cephadm/

Create a Ceph cluster:
```
# kcli create plan -f ceph_cluster.yml
```

Create a Ceph cluster for development use:
```
kcli create plan -f ceph_cluster.yml -P ceph_dev_folder=/home/me/Code/ceph
```
The parameter <<ceph_dev_folder>> must point to the folder where your Ceph code lives.


**Using Rook Operator:** 
https://rook.github.io/docs/rook/master/

Create a Ceph cluster:
```
# kcli create plan -f ./k8s/kubernetes.yml
```

A ceph toolbox is also deployed. It can be run using the command "c" in the k8 master vm. 

