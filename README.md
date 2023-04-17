# Validated Pattern Utility Container 

utility container for simplified execution of imperative commands in each of the patterns.

The tag used on the image represents the `oc` client version installed. <br/>
For example: `quay.io/hybridcloudpatterns/utility-container:stable-4.10.3` means that the openshift client (oc) version is `4.10.3`

```bash
$ podman run quay.io/hybridcloudpatterns/utility-container:stable-4.10.3` oc version 
Client Version: 4.10.3
```

### Installed Software

|               name                |  type    |   version    |
|:---------------------------------:|:--------:|:------------:|
|ansible                            |pip       |2.14.4        |
|argocd                             |binary    |v2.5.7+e0ee345|
|awscli                             |pip       |1.27.114      |
|azure-cli                          |pip       |2.47.0        |
|boto3                              |pip       |1.26.114      |
|botocore                           |pip       |1.29.114      |
|gcloud                             |pip       |0.18.3        |
|git-core                           |package   |2.31.1        |
|helm                               |binary    |v3.10.3       |
|jq                                 |package   |1.6           |
|kubernetes.core                    |collection|2.4.0         |
|kubernetes                         |pip       |26.1.0        |
|kustomize                          |binary    |v4.5.4        |
|make                               |package   |4.3           |
|openshift                          |binary    |4.11.25       |
|python3-pip                        |package   |21.2.3        |
|python                             |package   |3.9.14        |
|redhat_cop.controller_configuration|collection|2.3.1         |
|tar                                |package   |1.34          |
|tekton                             |binary    |0.29.0        |
|vi                                 |package   |8.2.2637      |

### Usage
**Pull the image**
```bash
podman pull quay.io/hybridcloudpatterns/utility-container:stable-4.10.3
```

**Use image to execute a playbook**
```bash
podman run quay.io/hybridcloudpatterns:stable-4.10.3 ansible-playbook <playbook>.yml 
```

### Build the image
Just run: `make build` and both amd64 and arm64 will be built locally (you will need the qemu-user-static package installed)

To upload the image to the official repo run: `make UPLOADREGISTRY=quay.io/hybridcloudpatterns upload` (by default it uploads somewhere else
to try and avoid accidental uploads)

