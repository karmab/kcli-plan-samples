curl -L https://github.com/istio/istio/releases/download/1.0.3/istio-1.0.3-linux.tar.gz | tar xz
cd istio-1.0.3
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
oc adm policy add-scc-to-user privileged -z default -n default
oc apply -f install/kubernetes/istio-demo.yaml
oc project istio-system
oc expose svc istio-ingressgateway
oc expose svc servicegraph
oc expose svc grafana
oc expose svc prometheus
oc expose svc tracing
