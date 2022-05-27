FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL maintainer Validated Patterns <team-validated-patterns@redhat.com>

USER root

RUN microdnf install --disableplugin=subscription-manager --nodocs python3-pip make git tar vi -y && \
    microdnf clean all && \
    rm -rf /var/cache/dnf && \
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
    chmod +x /usr/local/bin/argocd && \
    curl -sSL -o /usr/local/bin/helm https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 && \
    chmod +x /usr/local/bin/helm && \
    curl -sLfO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz && \
    tar xvf openshift-client-linux.tar.gz -C /usr/local/bin && \
    rm -rf openshift-client-linux.tar.gz 

ADD requirements.txt requirements.txt

RUN mkdir -m 770 /pattern && \
    mkdir -m 770 -p /pattern/.ansible && \
    chown -R 1001.1001 /pattern && \
    pip3 install --no-cache-dir --upgrade -r requirements.txt && \
    ansible-galaxy collection install kubernetes.core

USER 1001

WORKDIR /pattern
