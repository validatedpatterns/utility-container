FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ARG TITLE="utility-container"
ARG DESCRIPTION="Pattern Utility Container"
ARG MAINTAINER="Validated Patterns <team-validated-patterns@redhat.com>"
# https://spdx.org/licenses/
ARG LICENSE="Apache-2.0"
ARG URL="https://github.com/validatedpatterns"
ARG SOURCE="https://github.com/validatedpatterns/utility-container/blob/main/Containerfile"

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
ARG OPENSHIFT_CLIENT_VERSION="4.14.20"
ARG HYPERSHIFT_VERSION="2.7.2-1"
ARG HELM_VERSION="3.13.3"
ARG ARGOCD_VERSION="2.9.7"
ARG TKN_CLI_VERSION="0.35.2"
ARG YQ_VERSION="4.40.7"
ARG TEA_VERSION="0.9.2"

# As of 9/5/2024: awxkit is not compatible with python 3.12 due to setuptools
# Ansible-core 2.16 is needed for losing track of async jobs (as noted in AGOF for infra.controller_configuration)
# 'pip' will be influenced by where /usr/bin/python3 points, which we take care of with the altnernatives
# command
ARG PYTHON_VERSION="3.11"
ARG PYTHON_PKGS="python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python3-pip"
ARG ANSIBLE_CORE_SPEC="ansible-core==2.16.*"

# amd64 - arm64
ARG TARGETARCH
# x86_64 - aarch64
ARG ALTTARGETARCH
# '' - arm64-
ARG OPTTARGETARCH
# Extra rpms for specific arches. Needed because on arm64 pip insists on rebuilding psutils
ARG EXTRARPMS

USER root

ADD https://cli.github.com/packages/rpm/gh-cli.repo /etc/yum.repos.d/gh-cli.repo

# 'pip' is expected to be the pip resolved by 'python3 pip' AKA the one we install with PYTHON_VERSION
RUN microdnf --disableplugin=subscription-manager install -y ${PYTHON_PKGS} && microdnf --disableplugin=subscription-manager clean all
RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 0

# Add requirements.yml file for ansible collections
COPY requirements.yml /tmp/requirements.yml

RUN microdnf --disableplugin=subscription-manager install -y make git-core tar vi jq which findutils diffutils sshpass gzip gh $EXTRARPMS && \
microdnf remove -y $DNF_TO_REMOVE && \
rpm -e --nodeps $RPM_TO_FORCEFULLY_REMOVE && \
microdnf clean all && \
rm -rf /var/cache/dnf && \
curl -sSfL https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-${TARGETARCH} -o /usr/local/bin/argocd && \
curl -sSfL https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz | tar xzf - --strip-components=1 -C /usr/local/bin linux-${TARGETARCH}/helm && \
curl -sSfL https://github.com/tektoncd/cli/releases/download/v${TKN_CLI_VERSION}/tkn_${TKN_CLI_VERSION}_Linux_${ALTTARGETARCH}.tar.gz | tar xzf - -C /usr/local/bin tkn && \
curl -sSfL https://developers.redhat.com/content-gateway/file/pub/mce/clients/hcp-cli/${HYPERSHIFT_VERSION}/hcp-cli-${HYPERSHIFT_VERSION}-linux-${TARGETARCH}.tar.gz | tar xzf - -C /usr/local/bin ./hcp && \
curl -sSfL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_CLIENT_VERSION}/openshift-client-linux-${OPTTARGETARCH}${OPENSHIFT_CLIENT_VERSION}.tar.gz | tar xzf - -C /usr/local/bin oc && ln -sf /usr/local/bin/oc /usr/local/bin/kubectl && \
curl -sSfL https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} -o /usr/local/bin/yq && \
curl -sSfL https://gitea.com/gitea/tea/releases/download/v${TEA_VERSION}/tea-${TEA_VERSION}-linux-${TARGETARCH} -o /usr/local/bin/tea && \
chown root:root /usr/local/bin/* && chmod 755 /usr/local/bin/* && \
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

# We will have two important folders:
# /pattern which will have the current pattern's git repo bindmounted
# /pattern-home which stays inside the container only
# This split allows us to point all the ansible variables for temporary folders to
# stay inside /pattern-home in the container. This way we are not going to fight for permissions
# (normally a container can have trouble to write back to the host)
#USER 1001
ENV HOME=/pattern-home
ENV ANSIBLE_REMOTE_TMP=/pattern-home/.ansible/tmp
ENV ANSIBLE_ASYNC_DIR=/tmp/.ansible/.async
ENV ANSIBLE_LOCAL_TMP=/pattern-home/.ansible/tmp
ENV ANSIBLE_LOCALHOST_WARNING=False
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Add requirements.yml file for ansible collections
COPY requirements.yml /tmp/requirements.yml
COPY requirements.txt /tmp/requirements.txt

RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
ansible-galaxy collection install --collections-path /usr/share/ansible/collections -r /tmp/requirements.yml && \
rm -rf /usr/local/lib/python${PYTHON_VERSION}/site-packages/ansible_collections/$COLLECTIONS_TO_REMOVE && \
curl -sSfL -O https://raw.githubusercontent.com/clumio-code/azure-sdk-trim/main/azure_sdk_trim/azure_sdk_trim.py && \
python3 azure_sdk_trim.py && rm azure_sdk_trim.py && pip uninstall -y humanize && \
if [ -n "$EXTRARPMS" ]; then microdnf remove -y $EXTRARPMS; fi && \
mkdir -p /pattern/.ansible/tmp /pattern-home/.ansible/tmp && \
find /pattern/.ansible -type d -exec chmod 770 "{}" \; && \
find /pattern-home/.ansible -type d -exec chmod 770 "{}" \;


# Adding python scripts to start, stop and retrieve status of hostedcluster instnances
ADD https://raw.githubusercontent.com/validatedpatterns/utilities/main/aws-tools/start-instances.py \
    https://raw.githubusercontent.com/validatedpatterns/utilities/main/aws-tools/stop-instances.py \
    https://raw.githubusercontent.com/validatedpatterns/utilities/main/aws-tools/status-instances.py /usr/local/bin/

COPY default-cmd.sh /usr/local/bin
WORKDIR /pattern
CMD ["/usr/local/bin/default-cmd.sh"]
