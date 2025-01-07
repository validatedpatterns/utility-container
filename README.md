# Validated Pattern Utility Container

utility container for simplified execution of imperative commands in each of the patterns.


## Installed Software

|               name                |  type    |   version    |
|:---------------------------------:|:--------:|:------------:|
|ansible                            |pip       |2.16.14       |
|ansible.posix                      |collection|2.0.0         |
|ansible-runner                     |pip       |2.4.0         |
|ansible.utils                      |collection|5.1.2         |
|argocd                             |binary    |v2.9.7+fbb6b20|
|awscli                             |pip       |1.36.34       |
|awx.awx                            |collection|24.6.1        |
|awxkit                             |pip       |24.6.1        |
|azure-cli                          |pip       |2.67.0        |
|boto3                              |pip       |1.35.93       |
|botocore                           |pip       |1.35.93       |
|community.general                  |collection|10.2.0        |
|community.okd                      |collection|4.0.1         |
|gcloud                             |pip       |0.18.3        |
|git-core                           |package   |2.43.5        |
|hcp                                |binary    |4.17.0        |
|helm                               |binary    |v3.13.3       |
|infra.ah_configuration             |collection|2.1.0         |
|infra.controller_configuration     |collection|2.11.0        |
|infra.eda_configuration            |collection|1.1.0         |
|jmespath                           |pip       |1.0.1         |
|jq                                 |package   |1.6           |
|kubernetes.core                    |collection|5.0.0         |
|kubernetes                         |pip       |31.0.0        |
|kustomize                          |binary    |v5.0.1        |
|make                               |package   |4.3           |
|openshift                          |binary    |4.14.20       |
|pytest                             |pip       |8.3.4         |
|python3-pip                        |package   |21.3.1        |
|python                             |package   |3.11.9        |
|redhat_cop.controller_configuration|collection|2.3.1         |
|rhvp.cluster_utils                 |collection|1.0.2         |
|sshpass                            |package   |1.09          |
|tar                                |package   |1.34          |
|tea                                |binary    |0.9.2         |
|tekton                             |binary    |0.35.2        |
|vi                                 |package   |8.2.2637      |
|vp-qe-test-common                  |pip       |0.1.0         |

## Usage
**Pull the image**
```bash
podman pull quay.io/hybridcloudpatterns/utility-container:latest
```

**Use image to execute a playbook**
```bash
podman run -it --rm --net=host quay.io/hybridcloudpatterns/utility-container:latest ansible-playbook <playbook>.yml
```

## Build the image
Just run: `make build` and both amd64 and arm64 will be built locally (you will need the qemu-user-static package installed)

To upload the image to the official repository, run: `make UPLOADREGISTRY=quay.io/hybridcloudpatterns upload` (by default it uploads somewhere else
to try and avoid accidental uploads)

