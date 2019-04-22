oc adm policy add-scc-to-user anyuid -z build-controller -n knative-build
oc adm policy add-scc-to-user anyuid -z controller -n knative-serving
oc adm policy add-scc-to-user anyuid -z autoscaler -n knative-serving
oc adm policy add-scc-to-user anyuid -z kube-state-metrics -n knative-monitoring
oc adm policy add-scc-to-user anyuid -z node-exporter -n knative-monitoring
oc adm policy add-scc-to-user anyuid -z prometheus-system -n knative-monitoring
oc adm policy add-cluster-role-to-user cluster-admin -z build-controller -n knative-build
oc adm policy add-cluster-role-to-user cluster-admin -z controller -n knative-serving
curl -L https://storage.googleapis.com/knative-releases/serving/latest/serving.yaml | sed 's/LoadBalancer/NodePort/' | oc apply --filename -
#oc get cm config-network -n knative-serving -o yaml | sed  's@istio.sidecar.includeOutboundIPRanges:.*@istio.sidecar.includeOutboundIPRanges: "10.0.0.1/24"@'  | oc replace -f -
oc get cm config-network -n knative-serving -o yaml | sed  's@istio.sidecar.includeOutboundIPRanges:.*@istio.sidecar.includeOutboundIPRanges: "172.17.0.0/16"@'  | oc replace -f -
