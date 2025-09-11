# Validated Patterns Utility Container

![Version: 1.0.1](https://img.shields.io/badge/Version-1.0.1-informational?style=flat-square)
[![Quay Repository](https://img.shields.io/badge/Quay.io-utility--container-blue?logo=quay)](https://quay.io/repository/validatedpatterns/utility-container)
[![CI Pipeline](https://github.com/validatedpatterns/utility-container/actions/workflows/docker-publish.yml/badge.svg?branch=main)](https://github.com/validatedpatterns/utility-container/actions/workflows/docker-publish.yml)

A utility container for simplified execution of imperative commands in each of the Validated Patterns.

## Overview

This container provides a pre-configured environment with all the necessary tools and dependencies for working with Validated Patterns. It includes Ansible, Kubernetes tools, cloud CLIs, and other utilities commonly needed for pattern deployment and management.

## Installed Software

<!-- textlint-disable -->

|                name                 |    type    |    version     |
| :---------------------------------: | :--------: | :------------: |
|               ansible               |    pip     |    2.16.14     |
|            ansible.posix            | collection |     2.1.0      |
|           ansible-runner            |    pip     |     2.4.1      |
|            ansible.utils            | collection |     6.0.0      |
|               argocd                |   binary   | v2.9.7+fbb6b20 |
|               awscli                |    pip     |    1.42.25     |
|               awx.awx               | collection |     24.6.1     |
|               awxkit                |    pip     |     24.6.1     |
|              azure-cli              |    pip     |     2.77.0     |
|                boto3                |    pip     |    1.40.25     |
|              botocore               |    pip     |    1.40.25     |
|          community.general          | collection |     11.2.1     |
|            community.okd            | collection |     5.0.0      |
|               gcloud                |    pip     |     0.18.3     |
|                 gh                  |  package   |     2.78.0     |
|              git-core               |  package   |     2.47.3     |
|                gzip                 |  package   |      1.12      |
|                 hcp                 |   binary   |     4.17.0     |
|                helm                 |   binary   |    v3.13.3     |
|       infra.ah_configuration        | collection |     2.1.0      |
|   infra.controller_configuration    | collection |     3.1.3      |
|       infra.eda_configuration       | collection |     1.1.0      |
|              jmespath               |    pip     |     1.0.1      |
|                 jq                  |  package   |      1.6       |
|           kubernetes.core           | collection |     6.1.0      |
|             kubernetes              |    pip     |     33.1.0     |
|              kustomize              |   binary   |     v5.0.1     |
|                make                 |  package   |      4.3       |
|              openshift              |   binary   |    4.14.20     |
|               pytest                |    pip     |     8.4.2      |
|             python3-pip             |  package   |     21.3.1     |
|               python                |  package   |    3.11.11     |
| redhat_cop.controller_configuration | collection |     2.3.1      |
|         rhvp.cluster_utils          | collection |     1.1.0      |
|               sshpass               |  package   |      1.09      |
|                 tar                 |  package   |      1.34      |
|                 tea                 |   binary   |     0.9.2      |
|               tekton                |   binary   |     0.35.2     |
|                 vi                  |  package   |    8.2.2637    |
|          vp-qe-test-common          |    pip     |     0.1.0      |

<!-- textlint-enable -->

## Usage

### Pull the Image

```bash
podman pull quay.io/validatedpatterns/utility-container:latest
```

### Examples

**Interactive shell**

```bash
podman run --rm -it --net=host \
  --security-opt label=disable \
  -v ${HOME}:/pattern \
  -v ${HOME}:${HOME} \
  -w $(pwd) \
  quay.io/validatedpatterns/utility-container:latest sh
```

**Execute an Ansible playbook**

```bash
podman run --rm -it --net=host \
  --security-opt label=disable \
  -v ${HOME}:/pattern \
  -v ${HOME}:${HOME} \
  -w $(pwd) \
  quay.io/validatedpatterns/utility-container:latest \
  ansible-playbook <playbook>.yml
```

**Run OpenShift commands**

```bash
podman run --rm -it --net=host \
  --security-opt label=disable \
  -v ${HOME}:/pattern \
  -v ${HOME}:${HOME} \
  -w $(pwd) \
  quay.io/validatedpatterns/utility-container:latest \
  oc get nodes
```

## Troubleshooting

**Permission issues with volume mounts**

- Ensure the `--security-opt label=disable` flag is used when running the container.
- Check that your user has read/write access to the mounted directories.

**Network connectivity issues**

- Use `--net=host` for full network access.
- For restricted environments, configure appropriate network policies.

**Missing tools or outdated versions**

- Check the installed software table above for current versions.
- Consider building a custom image if you need different tool versions.

## Development

### Build the Image

Run `make build` to build both amd64 and arm64 architectures locally (requires qemu-user-static package).

### Upload to Registry

Run `make upload` to push the image to the official repository.

### Contributing

To update software versions or add new tools, modify the Containerfile and update the software table in this readme. Use `make versions` to generate the software versions table from the container after building locally.
