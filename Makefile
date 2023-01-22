CONTAINER="utility-container"
TAG="latest"

.PHONY: help
# No need to add a comment here as help is described in common/
help:
	@printf "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sort | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)\n"

.PHONY: build
build: podman-build versions ## Build the container locally and print installed versions

.PHONY: podman-build
podman-build:
	@echo "Building the utility container"
	buildah bud --format docker -f Containerfile -t ${CONTAINER}:${TAG}

.PHONY: versions
versions: ## Prints the versions of most tools inside the container
	@podman run --rm -it --net=host ${CONTAINER}:${TAG} sh -c \
		"echo '* Helm: '; helm version; \
		echo '* ArgoCD: '; argocd version --client ; \
		echo '* Tekton: '; tkn version ; \
		echo '* oc: '; oc version ; \
		echo '* Python: '; python --version ; \
		echo '* Ansible: '; ansible --version ; \
		echo '* kubernetes.core: '; ansible-galaxy collection list | grep kubernetes.core"

.PHONY: run
run: ## Runs the container interactively
	@podman run --rm -it --net=host ${CONTAINER}:${TAG} sh

.PHONY: upload
upload: build ## Builds and then uploads the container to quay.io/hybridcloudpatterns/${CONTAINER}:${TAG}
	@echo "Uploading the container to quay.io/hybridcloudpatterns/${CONTAINER}:${TAG}"
	buildah push localhost/${CONTAINER}:${TAG} quay.io/hybridcloudpatterns/${CONTAINER}:${TAG}
