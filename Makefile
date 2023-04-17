NAME ?= utility-container
TAG ?= latest
CONTAINER ?= $(NAME):$(TAG)

REGISTRY ?= localhost
UPLOADREGISTRY ?= quay.io/rhn_support_mbaldess

##@ Help-related tasks
.PHONY: help
help: ## Help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^(\s|[a-zA-Z_0-9-])+:.*?##/ { printf "  \033[36m%-35s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build-related tasks
.PHONY: build
build: manifest podman-build test ## Build the container locally (all arches) and print installed test

.PHONY: amd64
amd64: manifest podman-build-amd64 test-amd64 ## Build and test the container on amd64

.PHONY: arm64
arm64: manifest podman-build-amd64 test-amd64 ## Build and test the container on amd64

.PHONY: manifest
manifest: ## creates the buildah manifest for multi-arch images
	buildah manifest create "${REGISTRY}/${CONTAINER}"

.PHONY: podman-build
podman-build: podman-build-amd64 podman-build-arm64 ## Build both amd64 and arm64

.PHONY: podman-build-amd64
podman-build-amd64: ## build the container in amd64
	@echo "Building the utility container amd64"
	buildah bud --arch=amd64 --build-arg TARGETARCH=amd64 --build-arg ALTTARGETARCH=x86_64 \
		--build-arg OPTTARGETARCH='' --build-arg EXTRARPMS='' --format docker \
		-f Containerfile -t "${CONTAINER}-amd64"
	buildah manifest add --arch=amd64 "${REGISTRY}/${CONTAINER}" "${REGISTRY}/${CONTAINER}-amd64"

.PHONY: podman-build-arm64
podman-build-arm64: ## build the container in arm64
	@echo "Building the utility container arm64"
	buildah bud --arch=arm64 --build-arg TARGETARCH=arm64 --build-arg ALTTARGETARCH=aarch64 \
		--build-arg OPTTARGETARCH="arm64-" --build-arg EXTRARPMS="gcc python3-devel glibc-devel libxcrypt-devel" --format docker \
		-f Containerfile -t "${CONTAINER}-arm64"
	buildah manifest add --arch=arm64 "${REGISTRY}/${CONTAINER}" "${REGISTRY}/${CONTAINER}-arm64"

.PHONY: test-amd64
test-amd64: ## Prints the test of most tools inside the container amd64
	@echo "** Testing linux/amd64"
	@podman run --arch=amd64 --rm -it --net=host "${REGISTRY}/${CONTAINER}-amd64" bash -c \
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

.PHONY: test-arm64
test-arm64: ## Prints the test of most tools inside the container arm64
	@echo "** Testing linux/arm64"
	@podman run --arch=arm64 --rm -it --net=host "${REGISTRY}/${CONTAINER}-arm64" bash -c \
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
test: test-amd64 test-arm64 ## Tests the container for all the required bits both arm64 and amd64

##@ Run and upload tasks

.PHONY: run
run: ## Runs the container interactively
	podman run --rm -it --net=host \
		--security-opt label=disable \
		-v ${HOME}:/pattern \
		-v ${HOME}:${HOME} \
		-w $$(pwd) "${REGISTRY}/${CONTAINER}-amd64" sh

.PHONY: upload
upload: ## Uploads the container to quay.io/hybridcloudpatterns/${CONTAINER}
	@echo "Uploading the ${REGISTRY}/${CONTAINER} container to ${UPLOADREGISTRY}/${CONTAINER}"
	buildah manifest push --all "${REGISTRY}/${CONTAINER}" "docker://${UPLOADREGISTRY}/${CONTAINER}"

.PHONY: clean
clean: ## Removes any previously built artifact
	buildah manifest rm "${REGISTRY}/${CONTAINER}"
