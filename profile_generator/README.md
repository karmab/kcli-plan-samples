
# Profile Generator for Kcli
A Python script to update a YAML file with new data based on a Jinja2 template.

Installation
Clone this repository:
```sh
git clone https://github.com/tosin2013/kcli-plan-samples.git
```

Install the required dependencies:
```sh
pip install -r requirements.txt
```
Usage
To update the YAML file with new data, use the update-yaml command:

```sh
python profile_generator/profile_generator.py update-yaml OS_NAME TEMPLATE_PATH --image IMAGE_NAME --user USER_NAME --user-password USER_PASSWORD
```
Where:

* `OS_NAME:` The name of the operating system to update in the YAML file.
* `TEMPLATE_PATH:` The path to the Jinja2 template file.
* `IMAGE_NAME:` The name of the image.
* `USER_NAME:` The name of the user.
* `USER_PASSWORD:` The password of the user.

Options:

* `--rhnregister:` Enable RHN registration (default: False).
* `--rhnorg:` RHN organization name (default: '').
* `--rhnactivationkey:` RHN activation key (default: '').
* `--numcpus:` Number of CPUs (default: 2).
* `--memory:` Memory size in MB (default: 4096).
* `--disk-size:` Disk size in GB (default: 20).
* `--reservedns:` Reserve DNS name (default: False).
* `--net-name:` Network name (default: 'qubinet').
* `--offline-token:` Offline token (default: '').
* `--help, -h:` Display help message.

The update-yaml command updates the YAML file with the new data based on the Jinja2 template and saves it to `kcli-profiles.yml`. If the `--help` flag is passed, the command displays a help message with the available options and exits.

Examples
Here are some examples of using the update-yaml command:

```sh
# Update RHEL 9 entry in the YAML file with new data
python3 profile_generator/profile_generator.py update-yaml rhel9 rhel9/template.yaml --image rhel-baseos-9.1-x86_64-kvm.qcow2 --user admin --user-password secret

# Update Fedora 27 entry in the YAML file with new data
python3 profile_generator/profile_generator.py update-yaml fedora37 fedora37/template.yaml --image Fedora-Cloud-Base-37-1.7.x86_64.qcow2 --user admin --user-password secret --disk-size 30 --numcpus 4 --memory 8192 --user admin --user-password secret

# The kcli profiles yaml will be appened with the new data
$ cat kcli-profiles.yml                                                                                             04:51:01 PM
rhel9:
  cmds:
  - echo secret | passwd --stdin root
  - useradd admin
  - usermod -aG wheel admin
  - echo "admin ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/admin
  - echo secret | passwd --stdin admin
  disks:
  - size: 20
  image: rhel-baseos-9.1-x86_64-kvm.qcow2
  memory: 4096
  nets:
  - name: qubinet
  numcpus: 2
fedora37:
  cmds:
  - echo  | passwd --stdin root
  - useradd admin
  - usermod -aG wheel admin
  - echo "admin ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/admin
  - echo secret | passwd --stdin admin
  disks:
  - size: 30
  image: Fedora-Cloud-Base-37-1.7.x86_64.qcow2
  memory: 8192
  nets:
  - name: qubinet
  numcpus: 4
  reservedns: false

# Display help message
python3 profile_generator/profile_generator.py update-yaml --help
```
