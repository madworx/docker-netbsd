NETBSD_VERSION := ${NETBSD_VERSION}
SHELL := /bin/bash

NETBSD_SETS := "base etc man misc modules text kern-GENERIC"

#
# Please note: Squashing images requires --experimental to be provided to dockerd.
#

all:	build

tests:
	DOCKER_IMAGE="madworx/netbsd:$(NETBSD_VERSION)-x86_64" bats tests/*.bats

build:
	docker build --no-cache --build-arg=NETBSD_VERSION=$(NETBSD_VERSION) \
	  $$([[ "$${NETBSD_VERSION}" < "7" ]] && echo "--build-arg=NETBSD_MIRROR=http://ftp.netbsd.org/pub/NetBSD-archive") \
	  -t `echo "madworx/netbsd:$(NETBSD_VERSION)-x86_64" | tr '[:upper:]' '[:lower:]'` . || exit 1 ; \

run:
	echo "Starting NetBSD container(s)..."
	port=2221 ; for v in $(VERSIONS) ; do \
		docker stop netbsd-$$v >/dev/null 2>&1 || true ; \
		docker rm netbsd-$$v >/dev/null 2>&1 || true ; \
		let "port++" ; \
		docker run \
			-d \
			-e "SSH_PUBKEY=\"`ssh-add -L`\"" \
			-e "USER_ID=$${UID}" \
			-e "USER_NAME=$${USER}" \
			-p $$port:22 \
			-v $${HOME}:/bsd/home/$${USER} \
			--privileged \
			--hostname qemu-netbsd-$$v-`uname -m` \
			--name netbsd-$$v \
			madworx/netbsd:$$v-`uname -m` ; \
	done

push:
	docker push `echo "madworx/netbsd:$(NETBSD_VERSION)-x86_64" | tr '[:upper:]' '[:lower:]'`

shell:
	docker exec -it netbsd-7.1.2 /usr/bin/bsd /bin/sh

check:
	port=2221 ; for v in $(VERSIONS) ; do \
		let "port++" ; \
		ssh localhost -p $${port} uname -a ; \
	done

.PHONY: tests
