FROM registry.access.redhat.com/ubi9/ubi-minimal
LABEL maintainer Validated Patterns <team-validated-patterns@redhat.com>

ARG COLLECTIONS_TO_REMOVE="fortinet cisco dellemc f5networks junipernetworks mellanox netapp"
ARG DNF_TO_REMOVE="dejavu-sans-fonts langpacks-core-font-en langpacks-core-en langpacks-en"
ARG RPM_TO_FORCEFULLY_REMOVE="cracklib-dicts"
ARG OPENSHIFT_CLIENT_VERSION="4.10.3"

USER root

RUN microdnf install -y python3-pip make git-core tar vi && \
microdnf remove -y $DNF_TO_REMOVE && \
rpm -e --nodeps $RPM_TO_FORCEFULLY_REMOVE && \
microdnf clean all && \
rm -rf /var/cache/dnf && \
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
chmod +x /usr/local/bin/argocd && \
curl -sSL -o /usr/local/bin/helm https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 && \
chmod +x /usr/local/bin/helm && \
curl -sLfO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OPENSHIFT_CLIENT_VERSION/openshift-client-linux-$OPENSHIFT_CLIENT_VERSION.tar.gz && \
tar xvf openshift-client-linux-$OPENSHIFT_CLIENT_VERSION.tar.gz -C /usr/local/bin && \
rm -rf openshift-client-linux-$OPENSHIFT_CLIENT_VERSION.tar.gz  && rm -f /usr/local/bin/kubectl && ln -sf /usr/local/bin/oc /usr/local/bin/kubectl

# humanize is only needed for the trimming of the container
# See https://github.com/Azure/azure-sdk-for-python/issues/11149
# and https://github.com/Azure/azure-sdk-for-python/issues/17801
# The size of the azure sdk is ridiculous because they keep old (and unused
# APIs) around. We run this azure_sdk_trim.py to prune the unused APIs while
# still maintaining a good compatibility level
# We install the collection in /usr/share/ansible/collections
# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#collections-paths
# otherwise whatever user openshift runs the container with won't find the collection
RUN pip3 install --no-cache-dir "ansible-core>=2.9" kubernetes openshift "boto3>=1.21" "botocore>=1.24" "awscli>=1.22" "azure-cli>=2.34" gcloud humanize --upgrade && \
ansible-galaxy collection install --collections-path /usr/share/ansible/collections kubernetes.core && \
rm -rf /usr/local/lib/python3.9/site-packages/ansible_collections/$COLLECTIONS_TO_REMOVE && \
curl -L -O https://raw.githubusercontent.com/clumio-code/azure-sdk-trim/main/azure_sdk_trim/azure_sdk_trim.py && \
python azure_sdk_trim.py && rm azure_sdk_trim.py && pip3 uninstall -y humanize

RUN mkdir -m 770 /pattern && \
mkdir -m 770 -p /pattern/.ansible && \
chown -R 1001.1001 /pattern 

USER 1001

WORKDIR /pattern
