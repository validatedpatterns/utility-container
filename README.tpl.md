# Validated Patterns Utility Container

![Version: __VERSION__ ](https://img.shields.io/badge/Version-__VERSION__-informational?style=flat-square)
[![Quay Repository](https://img.shields.io/badge/Quay.io-utility--container-blue?logo=quay)](https://quay.io/repository/validatedpatterns/utility-container)
[![CI Pipeline](https://github.com/validatedpatterns/utility-container/actions/workflows/docker-publish.yml/badge.svg?branch=main)](https://github.com/validatedpatterns/utility-container/actions/workflows/docker-publish.yml)

A utility container for simplified execution of imperative commands in each of the Validated Patterns.

## Overview

This container provides a pre-configured environment with all the necessary tools and dependencies for working with Validated Patterns. It includes Ansible, Kubernetes tools, cloud CLIs, and other utilities commonly needed for pattern deployment and management.

## Installed Software

| name | type | version |
| :--- | :--- | :--- |
__SOFTWARE_TABLE__

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
