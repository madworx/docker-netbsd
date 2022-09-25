.SECONDARY:
SHELL := /bin/bash
NETBSD_MIRROR := "ftp://ftp.fi.netbsd.org/pub/NetBSD"
DOCKER_IMAGE=$(shell echo "madworx/netbsd:$(NETBSD_VERSION)" | sed 's#_##' | tr '[:upper:]' '[:lower:]')

all:	help

list-available-versions: ## List all available versions of NetBSD from network mirror.
	@curl --list-only "$(NETBSD_MIRROR)/" | sed -n 's#^NetBSD-##p' | grep -v RC | sort -V

build-all: ## Build docker images of all available versions of NetBSD
	ALL_VERSIONS="$(shell make list-available-versions)" ; \
	for NETBSD_VERSION in $${ALL_VERSIONS} ; do \
		set -e ; \
		export TAGS=($$(./generate-tags.py $${NETBSD_VERSION} $${ALL_VERSIONS})) ; \
		export DOCKER_IMAGE="madworx/netbsd:$${TAGS[0]}" ; \
		make build \
			NETBSD_MIRROR="$(NETBSD_MIRROR)" \
			NETBSD_VERSION="$${NETBSD_VERSION}" ; \
		for TAG in $${TAGS[@]:1} ; do \
			docker tag "$${DOCKER_IMAGE}" "madworx/netbsd:$${TAG}" ; \
		done \
	done

push-all: build-all ## Push all available versions built to docker hub
	ALL_VERSIONS="$(shell make list-available-versions)" ; \
	for NETBSD_VERSION in $${ALL_VERSIONS} ; do \
		set -e ; \
		echo "Pushing $${NETBSD_VERSION}" ; \
		export TAGS=($$(./generate-tags.py $${NETBSD_VERSION} $${ALL_VERSIONS})) ; \
		export DOCKER_IMAGE="madworx/netbsd:$${TAGS[0]}" ; \
		for TAG in $${TAGS[@]} ; do \
			docker push "madworx/netbsd:$${TAG}" ; \
		done \
	done

test: .prereq-vars ## Test a specific version of NETBSD_VERSION.
	DOCKER_IMAGE=$(DOCKER_IMAGE) bats tests/*.bats

build: .prereq-vars ## Build container for given NETBSD_VERSION. (E.g "9.3")
	make .built-$(NETBSD_VERSION) \
		NETBSD_MIRROR="$(NETBSD_MIRROR)" \
		NETBSD_VERSION="$(NETBSD_VERSION)" \
		DOCKER_IMAGE="$(DOCKER_IMAGE)"

.built-%: Dockerfile docker-entrypoint.sh
	docker build --no-cache \
	  --build-arg=NETBSD_MIRROR="$(NETBSD_MIRROR)" \
	  --build-arg=NETBSD_VERSION="$(NETBSD_VERSION)" \
	  -t $(DOCKER_IMAGE) . || exit 1
	touch $@

push: .prereq-vars ## Push specific NETBSD_VERSION container.
	docker push $(DOCKER_IMAGE)

.prereq-vars:
ifndef NETBSD_VERSION
	$(error NETBSD_VERSION not set)
endif

.PHONY: tests test check run shell push build build-all help .prereq-vars

help:
	@grep -h -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
