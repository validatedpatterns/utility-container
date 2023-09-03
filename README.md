# Validated Pattern Utility Container

utility container for simplified execution of imperative commands in each of the patterns.


## Installed Software

|               name                |  type    |   version    |
|:---------------------------------:|:--------:|:------------:|
|ansible                            |pip       |2.15.3        |
|argocd                             |binary    |v2.8.0+804d4b8|
|awscli                             |pip       |1.29.40       |
|azure-cli                          |pip       |2.51.0        |
|boto3                              |pip       |1.28.40       |
|botocore                           |pip       |1.31.40       |
|gcloud                             |pip       |0.18.3        |
|git-core                           |package   |2.39.3        |
|helm                               |binary    |v3.12.3       |
|hypershift                         |binary    |2e77f3e23328  |
|jq                                 |package   |1.6           |
|kubernetes.core                    |collection|2.4.0         |
|kubernetes                         |pip       |27.2.0        |
|kustomize                          |binary    |v4.5.7        |
|make                               |package   |4.3           |
|openshift                          |binary    |4.13.9        |
|python3-pip                        |package   |21.2.3        |
|python                             |package   |3.9.16        |
|redhat_cop.controller_configuration|collection|2.3.1         |
|sshpass                            |package   |1.09          |
|tar                                |package   |1.34          |
|tekton                             |binary    |0.31.2        |
|vi                                 |package   |8.2.2637      |

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

