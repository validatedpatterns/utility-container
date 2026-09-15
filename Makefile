NAME ?= utility-container
TAG ?= latest
CONTAINER ?= $(NAME):$(TAG)

REGISTRY ?= localhost
UPLOADREGISTRY ?= quay.io/validatedpatterns
TESTCOMMAND := "set -e; echo '* Helm: '; helm version; \
		echo '* oc: '; oc version ; \
		echo '* yq: '; yq --version ; \
		echo '* Python: '; python --version ; \
		echo '* Ansible: '; ansible --version ; \
		echo '* kubernetes.core: '; ansible-galaxy collection list | grep kubernetes.core ; \
		echo '* community.general: '; ansible-galaxy collection list | grep community.general ; \
		echo '* ansible.posix: '; ansible-galaxy collection list | grep ansible.posix ; \
		echo '* ansible.utils: '; ansible-galaxy collection list | grep ansible.utils ; \
		echo '* rhvp.cluster_utils: '; ansible-galaxy collection list | grep rhvp.cluster_utils ; \
		echo '* diff: '; diff --version ; \
		echo '* find: '; find --version ; \
		echo '* gzip: '; gzip --version ; \
		echo '* tea: '; tea --version" ;

##@ Help-related tasks
.PHONY: help
help: ## Help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^(\s|[a-zA-Z_0-9-])+:.*?##/ { printf "  \033[36m%-35s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo -e "\nCustom build+upload with: make UPLOADREGISTRY=quay.io/foo TAG=testme build upload\n"

##@ Build-related tasks
.PHONY: build
build: manifest podman-build test ## Build the container locally (all arches) and print installed test

.PHONY: amd64
amd64: manifest podman-build-amd64 test-amd64 ## Build and test the container on amd64

.PHONY: arm64
arm64: manifest podman-build-arm64 test-arm64 ## Build and test the container on amd64

.PHONY: manifest
manifest: ## creates the buildah manifest for multi-arch images
	# The rm is needed due to bug https://www.github.com/containers/podman/issues/19757
	buildah manifest rm "${REGISTRY}/${CONTAINER}" || /bin/true
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
		$(TESTCOMMAND)

.PHONY: test-arm64
test-arm64: ## Prints the test of most tools inside the container arm64
	@echo "** Testing linux/arm64"
	@podman run --arch=arm64 --rm -it --net=host "${REGISTRY}/${CONTAINER}-arm64" bash -c \
		$(TESTCOMMAND)

.PHONY: test
test: test-amd64 test-arm64 ## Tests the container for all the required bits both arm64 and amd64

VERSION ?=$(shell git describe --tags --abbrev=0 2>/dev/null || echo "N/A")
.PHONY: gen-docs
gen-docs: ## Print all the versions of software in the locally-built container
	@echo "Extracting versions and updating README.md..."
	@SOFTWARE_MANIFEST=$$(podman run --rm --net=host \
		--security-opt label=disable \
		-v ${HOME}:/pattern \
		-v ${HOME}:${HOME} \
		-w $$(pwd) "${REGISTRY}/${CONTAINER}-amd64" sh -c " \
		set -e; \
		for pkg in sshpass python3-pip git-core jq tar gzip make vim-minimal; do \
			echo \"\$$pkg package \$$(rpm -q --queryformat '%{VERSION}' \$$pkg )\"; \
		done; \
		for pip_pkg in \$$(awk -F'[=>@#]' '{print \$$1}' requirements.txt | xargs); do \
			[ -z \"\$$pip_pkg\" ] && continue; \
			echo \"\$$pip_pkg pip \$$(pip show \$$pip_pkg | awk '/^Version:/ {print \$$2}')\"; \
		done; \
		for coll in \$$(yq '.collections[].name' requirements.yml 2>/dev/null); do \
			echo \"\$$coll collection \$$(ansible-galaxy collection list \$$coll 2>/dev/null | grep \"^\$$coll\" | awk '{print \$$2}')\"; \
		done; \
		echo \"python package \$$(/usr/bin/python3 --version 2>/dev/null | awk '{print \$$2}')\"; \
		echo \"age binary \$$(age --version 2>/dev/null)\"; \
		echo \"helm binary \$$(helm version --template '{{ .Version }}' 2>/dev/null)\"; \
		echo \"helmsecrets binary \$$(helm plugin list 2>/dev/null | awk '/^secrets/ {print \$$2}')\"; \
		echo \"tea binary \$$(tea --version 2>/dev/null | awk '/^Version:/ {print \$$2}')\"; \
		echo \"openshift binary \$$(oc version --client -o json 2>/dev/null | jq -j '.releaseClientVersion')\"; \
		echo \"kustomize binary \$$(oc version --client -o json 2>/dev/null | jq -j '.kustomizeVersion')\"; \
		echo \"ansible pip \$$(ansible --version -o json 2>/dev/null | grep core | awk '{print \$$3}' | tr -d '\"],')\"; \
		" | sed -e 's/\x1b\[[0-9;]*m//g' | sort | awk '{print "| " $$1 " | " $$2 " | " $$3 " |"}'); \
	\
	awk -v version="$(VERSION)" -v table="$$SOFTWARE_MANIFEST" ' \
		{ \
			gsub(/__VERSION__/, version); \
			gsub(/__SOFTWARE_TABLE__/, table); \
			print; \
		}' README.tpl.md > README.md


.PHONY: run
run: ## Runs the container interactively
	podman run --rm -it --net=host \
		--security-opt label=disable \
		-v ${HOME}:/pattern \
		-v ${HOME}:${HOME} \
		-w $$(pwd) "${REGISTRY}/${CONTAINER}-amd64" sh

.PHONY: super-linter
super-linter: ## Runs super linter locally
	rm -rf .mypy_cache
	podman run -e RUN_LOCAL=true -e USE_FIND_ALGORITHM=true	\
					-e VALIDATE_CHECKOV=false \
					-e VALIDATE_GITHUB_ACTIONS_ZIZMOR=false \
					-e VALIDATE_DOCKERFILE_HADOLINT=false \
					-e VALIDATE_JSON_PRETTIER=false \
					-e VALIDATE_MARKDOWN_PRETTIER=false \
					-e VALIDATE_PYTHON_PYLINT=false \
					-e VALIDATE_SHELL_SHFMT=false \
					-e VALIDATE_TRIVY=false \
					-e VALIDATE_YAML=false \
					-e VALIDATE_YAML_PRETTIER=false \
					$(DISABLE_LINTERS) \
					-v $(PWD):/tmp/lint:rw,z \
					-w /tmp/lint \
					ghcr.io/super-linter/super-linter:slim-v8

.PHONY: upload
upload: ## Uploads the container to quay.io/validatedpatterns/${CONTAINER}
	@echo "Uploading the ${REGISTRY}/${CONTAINER} container to ${UPLOADREGISTRY}/${CONTAINER}"
	buildah manifest push --all --format v2s2 "${REGISTRY}/${CONTAINER}" "docker://${UPLOADREGISTRY}/${CONTAINER}"

.PHONY: clean
clean: ## Removes any previously built artifact
	buildah manifest rm "${REGISTRY}/${CONTAINER}"

##### HostedCluster Management tasks
.PHONY: cluster-status
cluster-status: ## Checks the status of hosted-cluster machines
	@echo "Getting status of hosted-cluster nodes"
	podman run --rm --net=host  \
	  --security-opt label=disable \
		-v ${HOME}:/pattern \
		-v ${HOME}:${HOME} \
		-v ${HOME}/.aws:/pattern-home/.aws \
		"${REGISTRY}/${CONTAINER}"  python3 /usr/local/bin/status-instances.py -f ${CLUSTER}


.PHONY: cluster-start
cluster-start: ## Starts the hosted-cluster machines
	@echo "Starting hosted-cluster nodes"
	podman run --rm --net=host  \
	  --security-opt label=disable \
		-v ${HOME}:/pattern \
		-v ${HOME}:${HOME} \
		-v ${HOME}/.aws:/pattern-home/.aws \
	  "${REGISTRY}/${CONTAINER}" python3 /usr/local/bin/start-instances.py -f ${CLUSTER}

.PHONY: cluster-stop
cluster-stop: ## Stops the hosted-cluster machines
	@echo "Stopping hosted-cluster nodes"
	podman run --rm --net=host  \
	  --security-opt label=disable \
		-v ${HOME}:/pattern \
		-v ${HOME}:${HOME} \
		-v ${HOME}/.aws:/pattern-home/.aws \
		"${REGISTRY}/${CONTAINER}" python3 /usr/local/bin/stop-instances.py -f ${CLUSTER}
