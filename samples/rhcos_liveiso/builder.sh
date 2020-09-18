sleep 30
cd /root
curl https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest-4.6/rhcos-live.x86_64.iso > rhcos-live.x86_64.iso
coreos-installer iso ignition embed -i source.ign rhcos-live.x86_64.iso
mv rhcos-live.x86_64.iso klive.iso
