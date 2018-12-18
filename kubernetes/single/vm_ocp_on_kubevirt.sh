ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
PUBKEY=`cat ~/.ssh/id_rsa.pub`
sed -i "s/PUBKEY/$PUBKEY/" /root/ocp_on_kubevirt.sh
sed -i "s/DATA/`cat /root/ocp_on_kubevirt.sh | base64 -w0`/" vm_ocp_on_kubevirt.yml
kubectl create -f vm_ocp_on_kubevirt.yml
