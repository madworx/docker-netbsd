VERSIONS = 7.1.2 7.0 6.1.5 6.1 6.0.6 6.0
SHELL := /bin/bash
QEMU_VERSION := v2.11.1

NETBSD_SETS := "base etc man misc modules text kern-GENERIC"

#
# Please note: Squashing images requires --experimental to be provided to dockerd.
#

all:	build

build-qemu:
	docker build --build-arg=QEMU_RELEASE=$(QEMU_VERSION) --force-rm \
		-f Dockerfile.qemu -t madworx/qemu:$(QEMU_VERSION) .
	docker tag madworx/qemu:$(QEMU_VERSION) madworx/qemu:latest

build:	build-qemu
	for v in $(VERSIONS) ; do \
		docker build --build-arg=NETBSD_VERSION=$$v \
		  -t `echo "madworx/netbsd:$$v-x86_64" | tr '[:upper:]' '[:lower:]'` . || exit 1 ; \
	done

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
	for v in $(VERSIONS) ; do \
		docker push madworx/netbsd:$$v-`uname -m` ; \
	done

shell:
	docker exec -it netbsd-7.1.2 /usr/bin/bsd /bin/sh

check:
	port=2221 ; for v in $(VERSIONS) ; do \
		let "port++" ; \
		ssh localhost -p $${port} uname -a ; \
	done
