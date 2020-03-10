ssh-keyscan -H {{ config_host }} >> ~/.ssh/known_hosts
echo -e "Host=*\nStrictHostKeyChecking=no\n" > .ssh/config
PULLSECRET=$(cat /root/openshift_pull.json | tr -d [:space:])
echo -e "pullSecret: |\n  $PULLSECRET" >> /root/install-config.yaml
SSHKEY=$(cat /root/.ssh/id_rsa.pub)
echo -e "sshKey: |\n  $SSHKEY" >> /root/install-config.yaml
{% if disconnected %}
grep -q imageContentSources /root/install-config.yaml
if [ "$?" != "0" ] ; then
cat << EOF >> /root/install-config.yaml
imageContentSources:
- mirrors:
  - $(hostname -f):5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
- mirrors:
  - $(hostname -f):5000/ocp4/openshift4
  source: registry.svc.ci.openshift.org/ocp/release
EOF
else
  IMAGECONTENTSOURCES="- mirrors:\n  - $(hostname -f):5000/ocp4/openshift4\n  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev\n- mirrors:\n  - $(hostname -f):5000/ocp4/openshift4\n  source: registry.svc.ci.openshift.org/ocp/release"
  sed -i "/imageContentSources/a${IMAGECONTENTSOURCES}" /root/install-config.yaml
fi
grep -q additionalTrustBundle /root/install-config.yaml
if [ "$?" != "0" ] ; then
  echo "additionalTrustBundle: |" >> /root/install-config.yaml
  sed -e 's/^/  /' /opt/registry/certs/domain.crt >>  /root/install-config.yaml
else
  LOCALCERT="-----BEGIN CERTIFICATE-----\n $(grep -v CERTIFICATE /opt/registry/certs/domain.crt | tr -d '[:space:]')\n  -----END CERTIFICATE-----"
  sed -i "/additionalTrustBundle/a${LOCALCERT}" /root/install-config.yaml
  sed -i 's/^-----BEGIN/ -----BEGIN/' /root/install-config.yaml
fi
{% endif %}
