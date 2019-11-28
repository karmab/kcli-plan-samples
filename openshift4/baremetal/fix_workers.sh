export PATH=/root:$PATH
export HOME=/root
export KUBECONFIG=/root/ocp/auth/kubeconfig
while true ; do
    WORKERS=$(oc get bmh -n openshift-machine-api -o name | grep worker)
    for worker in WORKERS ; do
    oc patch $worker --type json -p '[{ "op": "remove", "path": "/spec/hardwareProfile" }]'
    done
    if [ "$?" == "0" ] ; then
        exit 0
    else
        sleep 20
    fi
done
