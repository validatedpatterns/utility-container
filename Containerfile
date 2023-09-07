FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ARG TITLE="utility-container"
ARG DESCRIPTION="Pattern Utility Container"
ARG MAINTAINER="Validated Patterns <team-validated-patterns@redhat.com>"
# https://spdx.org/licenses/
ARG LICENSE="Apache-2.0"
ARG URL="https://github.com/hybrid-cloud-patterns"
ARG SOURCE="https://github.com/hybrid-cloud-patterns/utility-container/blob/main/Containerfile"
ARG HYPERSHIFT_URL="https://hypershift-cli-download-multicluster-engine.apps.hcp.aws.validatedpatterns.io/linux/amd64/hypershift.tar.gz"

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.title="${TITLE}" \
      org.opencontainers.image.description="${DESCRIPTION}" \
      org.opencontainers.image.url="${URL}" \
      org.opencontainers.image.source="${SOURCE}" \
      org.opencontainers.image.authors="${MAINTAINER}" \
      org.opencontainers.image.licenses="${LICENSE}" \
      name="${TITLE}" \
      maintainer="${MAINTAINER}" \
      license="${LICENSE}" \
      description="${DESCRIPTION}"

ARG COLLECTIONS_TO_REMOVE="fortinet cisco dellemc f5networks junipernetworks mellanox netapp"
ARG DNF_TO_REMOVE="dejavu-sans-fonts langpacks-core-font-en langpacks-core-en langpacks-en"
ARG RPM_TO_FORCEFULLY_REMOVE="cracklib-dicts"
# Versions
ARG OPENSHIFT_CLIENT_VERSION="4.13.9"
ARG HELM_VERSION="3.12.3"
ARG ARGOCD_VERSION="2.8.0"
ARG TKN_CLI_VERSION="0.31.2"
ARG YQ_VERSION="4.35.1"

# amd64 - arm64
ARG TARGETARCH
# x86_64 - aarch64
ARG ALTTARGETARCH
# '' - arm64-
ARG OPTTARGETARCH
# Extra rpms for specific arches. Needed because on arm64 pip insists on rebuilding psutils
ARG EXTRARPMS

USER root

RUN microdnf --disableplugin=subscription-manager install -y python3-pip make git-core tar vi jq which findutils diffutils sshpass $EXTRARPMS && \
microdnf remove -y $DNF_TO_REMOVE && \
rpm -e --nodeps $RPM_TO_FORCEFULLY_REMOVE && \
microdnf clean all && \
rm -rf /var/cache/dnf && \
curl -sfL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-${TARGETARCH} && \
chmod +x /usr/local/bin/argocd && \
curl -sLfO https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz && \
tar xf helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz --strip-component 1 -C /usr/local/bin && \
chmod +x /usr/local/bin/helm && rm -f /usr/local/bin/README.md && rm -f /usr/local/bin/LICENSE && \
rm -f helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz && \
curl -sLfO https://github.com/tektoncd/cli/releases/download/v${TKN_CLI_VERSION}/tkn_${TKN_CLI_VERSION}_Linux_${ALTTARGETARCH}.tar.gz && \
tar xf tkn_${TKN_CLI_VERSION}_Linux_${ALTTARGETARCH}.tar.gz -C /usr/local/bin --no-same-owner && chmod 755 /usr/local/bin/tkn && \
rm -f tkn_${TKN_CLI_VERSION}_Linux_${ALTTARGETARCH}.tar.gz && \
rm -f /usr/local/bin/README.md && rm -f /usr/local/bin/LICENSE && \
curl -skLfO ${HYPERSHIFT_URL} && \
tar xf hypershift.tar.gz -C /usr/local/bin/ && \
rm -f hypershift.tar.gz && \
curl -sLfO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_CLIENT_VERSION}/openshift-client-linux-${OPTTARGETARCH}${OPENSHIFT_CLIENT_VERSION}.tar.gz && \
tar xvf openshift-client-linux-${OPTTARGETARCH}${OPENSHIFT_CLIENT_VERSION}.tar.gz -C /usr/local/bin && \
rm -rf openshift-client-linux-${OPTTARGETARCH}${OPENSHIFT_CLIENT_VERSION}.tar.gz  && rm -f /usr/local/bin/kubectl && ln -sf /usr/local/bin/oc /usr/local/bin/kubectl && \
curl -sSL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} && chmod 755 /usr/local/bin/yq && \
rm -rf /root/anaconda* /root/original-ks.cfg /usr/local/README

# The hypershift cli is downloaded directly from the cluster.
# This could change when HCP goes GA - the alternative would
# be to compile our own, so this seemed the logical choice. 

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
ansible-galaxy collection install --collections-path /usr/share/ansible/collections kubernetes.core redhat_cop.controller_configuration && \
rm -rf /usr/local/lib/python3.9/site-packages/ansible_collections/$COLLECTIONS_TO_REMOVE && \
curl -L -O https://raw.githubusercontent.com/clumio-code/azure-sdk-trim/main/azure_sdk_trim/azure_sdk_trim.py && \
python azure_sdk_trim.py && rm azure_sdk_trim.py && pip3 uninstall -y humanize && \
if [ -n "$EXTRARPMS" ]; then microdnf remove -y $EXTRARPMS; fi && \
mkdir -p /pattern/.ansible/tmp /pattern-home/.ansible/tmp && \
find /pattern/.ansible -type d -exec chmod 770 "{}" \; && \
find /pattern-home/.ansible -type d -exec chmod 770 "{}" \;

# We will have two important folders:
# /pattern which will have the current pattern's git repo bindmounted
# /pattern-home which stays inside the container only
# This split allows us to point all the ansible variables for temporary folders to
# stay inside /pattern-home in the container. This way we are not going to fight for permissions
# (normally a container can have trouble to write back to the host)
#USER 1001
ENV HOME=/pattern-home
ENV ANSIBLE_REMOTE_TMP=/pattern-home/.ansible/tmp
ENV ANSIBLE_LOCAL_TMP=/pattern-home/.ansible/tmp
ENV ANSIBLE_LOCALHOST_WARNING=False

COPY default-cmd.sh /usr/local/bin
WORKDIR /pattern
CMD ["/usr/local/bin/default-cmd.sh"]
