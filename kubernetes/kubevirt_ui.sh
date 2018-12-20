kubectl create sa ui -n kubevirt
kubectl create rolebinding kweb-ui --clusterrole=cluster-admin --user=system:serviceaccount:kubevirt:ui
#kubectl create clusterrolebinding kweb-ui --clusterrole=edit --user=system:serviceaccount:kubevirt:ui
kubectl create -f /root/kubevirt_ui.yml -n kubevirt
