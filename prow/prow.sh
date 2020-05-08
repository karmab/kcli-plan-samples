kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/baremetal/service-nodeport.yaml
echo "3840925c868d1da0b7f030af298a02eb9821aefd" > x
echo """[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg""" > /etc/yum.repos.d/google-cloud-sdk.repo
yum -y install google-cloud-sdk python3 gcc gcc gcc-c++ git
curl -L https://github.com/bazelbuild/bazel/releases/download/2.2.0/bazel-2.2.0-linux-x86_64 > /usr/bin/bazel
chmod u+x /usr/bin/bazel
git clone https://github.com/kubernetes/test-infra.git
cd test-infra/
bazel run //prow/cmd/tackle
