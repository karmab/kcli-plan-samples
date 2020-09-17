sleep 30
curl https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest-4.6/rhcos-live.x86_64.iso > /root/rhcos-live.x86_64.iso
coreos-installer iso ignition embed -i /root/source.ign /root/rhcos-live.x86_64.iso
