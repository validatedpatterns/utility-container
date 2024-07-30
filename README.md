# Validated Pattern Utility Container

utility container for simplified execution of imperative commands in each of the patterns.


## Installed Software

|               name                |  type    |   version    |
|:---------------------------------:|:--------:|:------------:|
|ansible                       |pip       |2.15.12       |
|ansible.posix                 |collection|1.5.4         |
|ansible.utils                 |collection|5.0.0         |
|argocd                        |binary    |v2.9.7+fbb6b20|
|awscli                        |pip       |1.33.32       |
|awx.awx                       |collection|24.6.1        |
|awxkit                        |pip       |24.6.1        |
|azure-cli                     |pip       |2.62.0        |
|boto3                         |pip       |1.34.150      |
|botocore                      |pip       |1.34.150      |
|community.general             |collection|9.2.0         |
|community.okd                 |collection|4.0.0         |
|gcloud                        |pip       |0.18.3        |
|git-core                      |package   |2.43.5        |
|hcp                           |binary    |4.15.0        |
|helm                          |binary    |v3.13.3       |
|infra.controller_configuration|collection|2.9.0         |
|jmespath                      |pip       |1.0.1         |
|jq                            |package   |1.6           |
|kubernetes.core               |collection|5.0.0         |
|kubernetes                    |pip       |30.1.0        |
|kustomize                     |binary    |v5.0.1        |
|make                          |package   |4.3           |
|openshift                     |binary    |4.14.20       |
|python3-pip                   |package   |21.2.3        |
|python3-pytest                |package   |6.2.2         |
|python                        |package   |3.9.18        |
|sshpass                       |package   |1.09          |
|tar                           |package   |1.34          |
|tekton                        |binary    |0.35.2        |
|vi                            |package   |8.2.2637      |
|vp-qe-test-common             |pip       |0.1.0         |

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

