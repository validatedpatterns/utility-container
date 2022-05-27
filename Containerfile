FROM registry.access.redhat.com/ubi9/toolbox

LABEL maintainer Validated Patterns <team-validated-patterns@redhat.com>

ENV HOME=/opt/ansible \
    USER_UID=1001

RUN mkdir -p /etc/ansible \
    && echo "localhost ansible_connection=local" > /etc/ansible/hosts \
    && echo '[defaults]' > /etc/ansible/ansible.cfg \
    && echo 'roles_path = /opt/ansible/roles' >> /etc/ansible/ansible.cfg \
    && echo 'library = /usr/share/ansible/openshift' >> /etc/ansible/ansible.cfg \
    && mkdir -m 770 -p ${HOME}/.ansible/tmp \
    && chown -R ${USER_UID}:0 ${HOME} \
    && chmod ug+rwx ${HOME}

RUN dnf install --disableplugin=subscription-manager --nodocs -y python3-pip \
 && curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 \
 && chmod +x /usr/local/bin/argocd \
 && curl -sSL -o /usr/local/bin/helm https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/helm/latest/helm-linux-amd64 \
 && chmod +x /usr/local/bin/helm \
 && curl -sLfO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz \
 && tar xvf openshift-client-linux.tar.gz -C /usr/local/bin \
 && rm -rf openshift-client-linux.tar.gz 

ADD requirements.txt requirements.txt

RUN pip3 install --no-cache-dir --upgrade -r requirements.txt \
 && ansible-galaxy collection install kubernetes.core

WORKDIR ${HOME}
USER ${USER_UID}
