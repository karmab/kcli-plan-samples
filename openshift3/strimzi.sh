VERSION="0.11.1"
oc project myproject
oc apply -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/$VERSION/strimzi-cluster-operator-$VERSION.yaml -n myproject
oc apply -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/$VERSION/examples/kafka/kafka-persistent.yaml -n myproject
