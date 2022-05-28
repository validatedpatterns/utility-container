ARG COLLECTIONS_TO_REMOVE="fortinet cisco dellemc f5networks junipernetworks mellanox netapp"
FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL maintainer Validated Patterns <team-validated-patterns@redhat.com>

USER root

RUN microdnf install python3-pip make git tar vi -y && \
microdnf clean all && \
rm -rf /var/cache/dnf && \
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
chmod +x /usr/local/bin/argocd && \
curl -sSL -o /usr/local/bin/helm https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 && \
chmod +x /usr/local/bin/helm && \
curl -sLfO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.10.3/openshift-client-linux-4.10.3.tar.gz && \
tar xvf openshift-client-linux-4.10.3.tar.gz -C /usr/local/bin && \
rm -rf openshift-client-linux-4.10.3.tar.gz 

RUN pip3 install --no-cache-dir  ansible-core>=2.9 kubernetes openshift boto3>=1.21 botocore>=1.24 awscli>=1.22 azure-cli>=2.34 gcloud --upgrade && \
ansible-galaxy collection install kubernetes.core && \
rm -rf /usr/local/lib/python3.9/site-packages/ansible_collections/$COLLECTIONS_TO_REMOVE

RUN mkdir -m 770 /pattern && \
mkdir -m 770 -p /pattern/.ansible && \
chown -R 1001.1001 /pattern 

USER 1001

WORKDIR /pattern
