NAME ?= utility-container
TAG ?= latest
CONTAINER ?= $(NAME):$(TAG)

REGISTRY ?= localhost
UPLOADREGISTRY ?= quay.io/hybridcloudpatterns
TESTCOMMAND := "set -e; echo '* Helm: '; helm version; \
		echo '* ArgoCD: '; argocd version --client ; \
		echo '* Tekton: '; tkn version ; \
		echo '* oc: '; oc version ; \
		echo '* yq: '; yq --version ; \
		echo '* Python: '; python --version ; \
		echo '* Ansible: '; ansible --version ; \
		echo '* kubernetes.core: '; ansible-galaxy collection list | grep kubernetes.core ; \
		echo '* redhat_cop.controller_configuration: '; ansible-galaxy collection list | grep redhat_cop.controller_configuration ; \
		echo '* infra.controller_configuration: '; ansible-galaxy collection list | grep infra.controller_configuration ; \
		echo '* infra.eda_configuration: '; ansible-galaxy collection list | grep infra.eda_configuration ; \
		echo '* infra.ah_configuration: '; ansible-galaxy collection list | grep infra.ah_configuration ; \
		echo '* awx.awx: '; ansible-galaxy collection list | grep awx.awx ; \
		echo '* community.general: '; ansible-galaxy collection list | grep community.general ; \
		echo '* ansible.posix: '; ansible-galaxy collection list | grep ansible.posix ; \
		echo '* ansible.utils: '; ansible-galaxy collection list | grep ansible.utils ; \
		echo '* rhvp.cluster_utils: '; ansible-galaxy collection list | grep rhvp.cluster_utils ; \
		echo '* diff: '; diff --version ; \
		echo '* find: '; find --version ; \
		echo '* tea: '; tea --version" ;

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

##@ Run and upload tasks
.PHONY: versions
versions: ## Print all the versions of software in the locally-built container
	@podman run --rm -it --net=host \
		--security-opt label=disable \
		-v ${HOME}:/pattern \
		-v ${HOME}:${HOME} \
		-w $$(pwd) "${REGISTRY}/${CONTAINER}-amd64" sh -c \
		"set -e; \
		echo -n \"|sshpass package \"; rpm -q --queryformat '%{VERSION}' sshpass; echo \" \"; \
		echo -n \"|python3-pip package \"; rpm -q --queryformat '%{VERSION}' python3-pip; echo \" \"; \
		echo -n \"|git-core package \"; rpm -q --qf '%{VERSION}' git-core; echo \" \"; \
		echo -n \"|vi package \"; rpm -q --qf '%{VERSION}' vim-minimal; echo \" \";  \
		echo -n \"|tar package \"; rpm -q --qf '%{VERSION}' tar;  echo \" \"; \
		echo -n \"|make package \"; rpm -q --qf '%{VERSION}' make;  echo \" \"; \
		echo -n \"|python package \";  /usr/bin/python3 --version | sed -e s'/Python //' | tr -d '\n';  echo \" \"; \
		echo -n \"|jq package \"; rpm -q --qf '%{VERSION}' jq;  echo \" \"; \
		echo -n \"|argocd binary \"; argocd version --client -o json | jq -j '.client.Version';  echo \" \"; \
		echo -n \"|helm binary \"; helm version --template '{{ .Version }}';  echo \" \"; \
		echo -n \"|tea binary \"; tea --version | sed -e 's/Version: //' | sed -e 's/golang.*//' | tr -d '\t' | tr -d '\n';  echo \" \"; \
		echo -n \"|tekton binary \"; tkn version --component client | tr -d '\n';  echo \" \"; \
		echo -n \"|openshift binary \"; oc version --client -o json | jq -j '.releaseClientVersion';  echo \" \"; \
		echo -n \"|kustomize binary \"; oc version --client -o json | jq -j '.kustomizeVersion';  echo \" \"; \
		echo -n \"|hcp binary \"; hcp --version version | cut -d: -f3 | tr -d '\n';  echo \" \"; \
		echo -n \"|pytest pip \"; pip show pytest | grep ^Version | cut -f2 -d\  |tr -d '\n'; echo \" \"; \
		echo -n \"|ansible pip \"; ansible --version -o json | grep core | cut -f3 -d\ | tr -d '\n]';  echo \" \"; \
		echo -n \"|kubernetes pip \"; pip show kubernetes |grep ^Version: | cut -f2 -d\ | tr -d '\n';  echo \" \"; \
		echo -n \"|boto3 pip \"; pip show boto3 | grep ^Version: | cut -f2 -d\ |tr -d '\n';  echo \" \"; \
		echo -n \"|botocore pip \"; pip show botocore | grep ^Version: | cut -f2 -d\ |tr -d '\n';  echo \" \"; \
		echo -n \"|awscli pip \"; pip show awscli | grep ^Version: | cut -f2 -d\ |tr -d '\n';  echo \" \"; \
		echo -n \"|azure-cli pip \"; pip show azure-cli | grep ^Version: | cut -f2 -d\ | tr -d '\n';  echo \" \"; \
		echo -n \"|gcloud pip \"; pip show gcloud| grep ^Version: | cut -f2 -d\ |tr -d '\n';  echo \" \"; \
		echo -n \"|awxkit pip \"; pip show awxkit| grep ^Version: | cut -f2 -d\ |tr -d '\n';  echo \" \"; \
		echo -n \"|jmespath pip \"; pip show jmespath| grep ^Version: | cut -f2 -d\ |tr -d '\n';  echo \" \"; \
		echo -n \"|ansible-runner pip \"; pip show ansible-runner| grep ^Version: | cut -f2 -d\ |tr -d '\n';  echo \" \"; \
		echo -n \"|vp-qe-test-common pip \"; pip show vp-qe-test-common | grep ^Version: | cut -f2 -d\ | tr -d '\n';  echo \" \"; \
		echo -n \"|kubernetes.core collection \";  ansible-galaxy collection list kubernetes.core |grep ^kubernetes.core | cut -f2 -d\  |tr -d '\n';  echo \" \"; \
		echo -n \"|community.okd collection \";  ansible-galaxy collection list community.okd |grep ^community.okd | cut -f2 -d\  |tr -d '\n';  echo \" \"; \
		echo -n \"|community.general collection \";  ansible-galaxy collection list community.general |grep ^community.general | cut -f2 -d\  |tr -d '\n';  echo \" \"; \
		echo -n \"|awx.awx collection \";  ansible-galaxy collection list awx.awx |grep ^awx.awx | tr -s ' ' | cut -f2 -d ' '  |tr -d '\n';  echo \" \"; \
		echo -n \"|ansible.posix collection \";  ansible-galaxy collection list ansible.posix |grep ^ansible.posix | cut -f2 -d\  |tr -d '\n';  echo \" \"; \
		echo -n \"|ansible.utils collection \";  ansible-galaxy collection list ansible.utils |grep ^ansible.utils | cut -f2 -d\  |tr -d '\n';  echo \" \"; \
		echo -n \"|rhvp.cluster_utils collection \";  ansible-galaxy collection list rhvp.cluster_utils |grep ^rhvp.cluster_utils | cut -f2 -d\  |tr -d '\n';  echo \" \"; \
		echo -n \"|redhat_cop.controller_configuration collection \";  ansible-galaxy collection list redhat_cop.controller_configuration |grep ^redhat_cop.controller_configuration | cut -f2 -d\ | tr -d '\n'; echo \" \";  \
		echo -n \"|infra.controller_configuration collection \";  ansible-galaxy collection list infra.controller_configuration |grep ^infra.controller_configuration | cut -f2 -d\ | tr -d '\n'; echo \" \";  \
		echo -n \"|infra.eda_configuration collection \";  ansible-galaxy collection list infra.eda_configuration |grep ^infra.eda_configuration | cut -f2 -d\ | tr -d '\n'; echo \" \";  \
		echo -n \"|infra.ah_configuration collection \";  ansible-galaxy collection list infra.ah_configuration |grep ^infra.ah_configuration | cut -f2 -d\ | tr -d '\n'; echo \" \";  \
    " | sort | column --table -o '|'

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
					-e VALIDATE_DOCKERFILE_HADOLINT=false \
					-e VALIDATE_JSON_PRETTIER=false \
					-e VALIDATE_MARKDOWN_PRETTIER=false \
					-e VALIDATE_KUBERNETES_KUBECONFORM=false \
					-e VALIDATE_MARKDOWN_PRETTIER=false \
					-e VALIDATE_PYTHON_PYLINT=false \
					-e VALIDATE_SHELL_SHFMT=false \
					-e VALIDATE_YAML=false \
					-e VALIDATE_YAML_PRETTIER=false \
					$(DISABLE_LINTERS) \
					-v $(PWD):/tmp/lint:rw,z \
					-w /tmp/lint \
					ghcr.io/super-linter/super-linter:slim-v7

.PHONY: upload
upload: ## Uploads the container to quay.io/hybridcloudpatterns/${CONTAINER}
	@echo "Uploading the ${REGISTRY}/${CONTAINER} container to ${UPLOADREGISTRY}/${CONTAINER}"
	buildah manifest push --all "${REGISTRY}/${CONTAINER}" "docker://${UPLOADREGISTRY}/${CONTAINER}"

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

