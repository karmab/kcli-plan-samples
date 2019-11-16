export PATH=/root:$PATH
export HOME=/root
export KUBECONFIG=/root/{{ cluster }}/auth/kubeconfig
while True ; do
    oc create -f metal3-config.yaml -n openshift-machine-api
    if [ "$?" == "0"] ; then
        exit 0
    else
        sleep 20
    fi
done
