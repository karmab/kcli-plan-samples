ISTIO={{ istio_version }}
if [ "$ISTIO" == "latest" ] ; then
curl -L https://git.io/getLatestIstio | sh -
else
curl -L https://github.com/istio/istio/releases/download/$ISTIO/istio-$ISTIO-linux.tar.gz | tar xz
fi
cd istio-*.*.*
export ISTIO_HOME=`pwd`
export PATH=$ISTIO_HOME/bin:$PATH
oc apply -f install/kubernetes/helm/istio/templates/crds.yaml
oc create ns istio-system
oc adm policy add-scc-to-user anyuid -z istio-cleanup-secrets-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-galley-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-security-post-install-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
oc label namespace default istio-injection=enabled
oc adm policy add-scc-to-user privileged -z default -n default
oc apply -f install/kubernetes/istio-demo.yaml
oc project istio-system
oc expose svc istio-ingressgateway
oc expose svc servicegraph
oc expose svc grafana
oc expose svc prometheus
oc expose svc tracing
{% if knative %}
oc adm policy add-scc-to-user anyuid -z build-controller -n knative-build
oc adm policy add-scc-to-user anyuid -z controller -n knative-serving
oc adm policy add-scc-to-user anyuid -z autoscaler -n knative-serving
oc adm policy add-scc-to-user anyuid -z kube-state-metrics -n knative-monitoring
oc adm policy add-scc-to-user anyuid -z node-exporter -n knative-monitoring
oc adm policy add-scc-to-user anyuid -z prometheus-system -n knative-monitoring
oc adm policy add-cluster-role-to-user cluster-admin -z build-controller -n knative-build
oc adm policy add-cluster-role-to-user cluster-admin -z controller -n knative-serving
curl -L https://storage.googleapis.com/knative-releases/serving/latest/release-lite.yaml | sed 's/LoadBalancer/NodePort/' | oc apply -f -
{% endif %}
reboot
