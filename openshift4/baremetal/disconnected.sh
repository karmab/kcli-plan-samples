yum -y install podman httpd httpd-tools jq
mkdir -p /opt/registry/{auth,certs,data}
export PRIMARY_IP=$(ip -4 -o addr show baremetal  | awk '{print $4}' | cut -d'/' -f1)
openssl req -newkey rsa:4096 -nodes -sha256 -keyout /opt/registry/certs/domain.key -x509 -days 365 -out /opt/registry/certs/domain.crt -subj "/C=US/ST=Madrid/L=San Bernardo/O=Karmalabs/OU=Guitar/CN=$(hostname -f )" -addext "subjectAltName=IP:$PRIMARY_IP"
cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
htpasswd -bBc /opt/registry/auth/htpasswd dummy dummy
podman create --name registry -p 5000:5000 --security-opt label=disable -v /opt/registry/data:/var/lib/registry:z -v /opt/registry/auth:/auth:z -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" -e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v /opt/registry/certs:/certs:z -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key docker.io/library/registry:2
podman start registry
export OPENSHIFT_RELEASE_IMAGE=registry.svc.ci.openshift.org/ocp/release:{{ tag }}
export OCP_RELEASE={{ tag }}
export LOCAL_REG="$PRIMARY_IP:5000"
export LOCAL_REPO='ocp4/openshift4'
export PULL_SECRET="/root/openshift_pull.json"
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE}
jq ".auths += {\"$PRIMARY_IP:5000\": {\"auth\": \"ZHVtbXk6ZHVtbXk=\",\"email\": \"jhendrix@karmalabs.com\"}}" < $PULL_SECRET > /root/temp.json
mv /root/temp.json $PULL_SECRET
oc adm release mirror -a $PULL_SECRET --from=$OPENSHIFT_RELEASE_IMAGE --to-release-image=$LOCAL_REG/$LOCAL_REPO:$OCP_RELEASE --to=$LOCAL_REG/$LOCAL_REPO

grep -q additionalTrustBundle /root/install-config.yaml
if [ "$?" != "0" ] ; then
  echo "additionalTrustBundle: |" >> /root/install-config.yaml
  sed -e 's/^/  /' /opt/registry/certs/domain.crt >>  /root/install-config.yaml
else
  LOCALCERT="-----BEGIN CERTIFICATE-----\n  $(grep -v CERTIFICATE /opt/registry/certs/domain.crt | tr -d '[:space:]')\n  -----END CERTIFICATE-----"
  sed -i "/additionalTrustBundle/a${LOCALCERT}" /root/install-config.yaml
  sed -i 's/^-----BEGIN/  -----BEGIN/' /root/install-config.yaml
fi
cat << EOF >> /root/install-config.yaml
imageContentSources:
- mirrors:
  - $PRIMARY_IP:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
- mirrors:
  - $PRIMARY_IP:5000/ocp4/openshift4
  source: registry.svc.ci.openshift.org/ocp/release
EOF
