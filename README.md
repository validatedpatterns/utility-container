# Validated Pattern Utility Container 

utility container for simplified execution of imperative commands in each of the patterns.

The tag used on the image represents the `oc` client version installed. <br/>
For example: `quay.io/hybrid-cloud-patterns/utility-container:stable-4.10.3` means that the openshift client (oc) version is `4.10.3`

```bash
$ podman run quay.io/hybrid-cloud-patterns/utility-container:stable-4.10.3` oc version 
Client Version: 4.10.3
```

### Installed Software

|    name     |  type   |
|:-----------:|:-------:|
| python3-pip | package |
|  git-core   | package |
|     vi      | package |
|    helm     | binary  |
|     tar     | package |
|    make     | package |
|   argocd    | binary  |
|   ansible   |   pip   |
| kubernetes  |   pip   |
|  openshift  |   pip   |
|    boto3    |   pip   |
|  botocore   |   pip   |
|   awscli    |   pip   |
|  azure-cli  |   pip   |
|   gcloud    |   pip   |


### The ansible-galaxy collection installed:
| ansible-collections |
| ------------------- |
| kubernetes.core |

### Usage
**Pull the image**
```bash
podman pull quay.io/hybrid-cloud-patterns/utility-container:stable-4.10.3
```

**Use image to execute a playbook**
```bash
podman run quay.io/hybrid-cloud-patterns:stable-4.10.3 ansible-playbook <playbook>.yml 
```
