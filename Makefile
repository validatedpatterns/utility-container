NAME="utility-container"
TAG="latest"
CONTAINER ?= $(NAME):$(TAG)

##@ Help-related tasks
.PHONY: help
help: ## Help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^(\s|[a-zA-Z_0-9-])+:.*?##/ { printf "  \033[36m%-35s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build-related tasks
.PHONY: build
build: podman-build versions ## Build the container locally and print installed versions

.PHONY: podman-build
podman-build:
	@echo "Building the utility container"
	buildah bud --format docker -f Containerfile -t ${CONTAINER}

.PHONY: versions
versions: ## Prints the versions of most tools inside the container
	@podman run --rm -it --net=host ${CONTAINER} bash -c \
		"set -e; echo '* Helm: '; helm version; \
		echo '* ArgoCD: '; argocd version --client ; \
		echo '* Tekton: '; tkn version ; \
		echo '* oc: '; oc version ; \
		echo '* kustomize: '; kustomize version ; \
		echo '* yq: '; yq --version ; \
		echo '* Python: '; python --version ; \
		echo '* Ansible: '; ansible --version ; \
		echo '* kubernetes.core: '; ansible-galaxy collection list | grep kubernetes.core ; \
		echo '* redhat_cop.controller_configuration: '; ansible-galaxy collection list | grep redhat_cop.controller_configuration ; \
		echo '* diff: '; diff --version ; \
		echo '* find: '; find --version"

.PHONY: test
test: versions ## Tests the container for all the required bits

##@ Run and upload tasks

.PHONY: run
run: ## Runs the container interactively
	podman run --rm -it --net=host \
		--security-opt label=disable \
		-v ${HOME}:/pattern \
		-v ${HOME}:${HOME} \
		-w $$(pwd) ${CONTAINER} sh

.PHONY: upload
upload: build ## Builds and then uploads the container to quay.io/hybridcloudpatterns/${CONTAINER}
	@echo "Uploading the container to quay.io/hybridcloudpatterns/${CONTAINER}"
	buildah push localhost/${CONTAINER} quay.io/hybridcloudpatterns/${CONTAINER}
