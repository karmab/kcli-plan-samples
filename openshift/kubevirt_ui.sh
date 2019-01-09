oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:kubevirt:default
oc apply -f kubevirt_ui.yml -n kubevirt
