{% if sdn == 'calico' %}
CIDR="192.168.0.0/16"
{% else %} 
CIDR="10.244.0.0/16"
{% endif %} 
#kubeadm init --pod-network-cidr=${CIDR}
kubeadm init --config /root/config.yml
cp /etc/kubernetes/admin.conf /root/
chown root:root /root/admin.conf
export KUBECONFIG=/root/admin.conf
echo "export KUBECONFIG=/root/admin.conf" >>/root/.bashrc
kubectl taint nodes --all node-role.kubernetes.io/master-
{% if sdn == 'flannel' %}
FLANNEL={{ flannel_version }}
if [ "$FLANNEL" == "latest" ] ; then
  FLANNEL=`curl -s https://api.github.com/repos/coreos/flannel/releases/latest| jq -r .tag_name`
fi
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/$FLANNEL/Documentation/kube-flannel.yml
{% elif sdn == 'weavenet' %}
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=`kubectl version | base64 | tr -d '\n'`"
{% elif sdn == 'calico' %}
kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
{% elif sdn == 'canal' %}
kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/canal/rbac.yaml
kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/canal/canal.yaml
{% elif sdn == 'romana' %}
kubectl apply -f https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-kubeadm.yml
{% endif %} 
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config
#export CMD=`kubeadm token create --print-join-command`
#echo ${CMD} > /root/join.sh
CMD="kubeadm join --config /root/join.yml"
IP=`ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
TOKEN=`kubeadm token create --ttl 0`
HASH=`openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1`
sed -i "s/IP/$IP/" /root/join.yml
sed -i "s/TOKEN/$TOKEN/" /root/join.yml
sed -i "s/HASH/$HASH/" /root/join.yml

sleep 160
{% if nodes > 0 %}
{% for number in range(0,nodes) %}
ssh-keyscan -H {{ prefix }}node0{{ number +1 }} >> ~/.ssh/known_hosts
scp /etc/kubernetes/admin.conf root@{{ prefix }}node0{{ number + 1 }}:/etc/kubernetes/
scp /root/join.yml root@{{ prefix }}node0{{ number + 1 }}:/root/
ssh root@{{ prefix }}node0{{ number +1 }} ${CMD} > /root/{{ prefix }}node0{{ number +1 }}.log
{% endfor %}
{% endif %}
