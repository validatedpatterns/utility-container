FROM registry.access.redhat.com/ubi8/ubi-minimal

LABEL maintainer Validated Patterns <team-validated-patterns@redhat.com>

RUN microdnf install python3-pip git -y && \
microdnf clean all && \
rm -rf /var/cache/dnf && \
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
chmod +x /usr/local/bin/argocd && \
curl -sSL -o /usr/local/bin/helm https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 && \
chmod +x /usr/local/bin/helm && \
pip3 install --no-cache-dir pip --upgrade && \
pip3 install --no-cache-dir  ansible>=2.9 && \
pip3 install --no-cache-dir kubernetes openshift boto3>=1.21 botocore>=1.24 awscli>=1.22 azure-cli>=2.34 gcloud --upgrade && \
ansible-galaxy collection install kubernetes.core 

RUN microdnf update -y python3-pip && \
microdnf clean all && \
rm -rf /var/cache/dnf
