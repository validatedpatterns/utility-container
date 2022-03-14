FROM registry.access.redhat.com/ubi8/ubi-minimal

LABEL maintainer Validated Patterns <team-validated-patterns@redhat.com>

USER root

RUN microdnf install python3-pip git tar -y && \
microdnf clean all && \
rm -rf /var/cache/dnf && \
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
chmod +x /usr/local/bin/argocd && \
curl -sSL -o /usr/local/bin/helm https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 && \
chmod +x /usr/local/bin/helm && \
curl -sLfO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.10.3.tar.gz && \
tar xvf openshift-client-linux-4.10.3.tar.gz -C /usr/local/bin && \
rm -rf openshift-client-linux-4.10.3.tar.gz && \
pip3 install --no-cache-dir pip --upgrade && \
pip3 install --no-cache-dir  ansible>=2.9 && \
pip3 install --no-cache-dir kubernetes openshift boto3>=1.21 botocore>=1.24 awscli>=1.22 azure-cli>=2.34 gcloud --upgrade && \
ansible-galaxy collection install kubernetes.core 

USER root

RUN microdnf update -y python3-pip && \
microdnf clean all && \
rm -rf /var/cache/dnf

USER 1001
