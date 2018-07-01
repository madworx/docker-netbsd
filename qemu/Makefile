QEMU_VERSION := v2.11.1

all:	build

build:
	docker build --build-arg=QEMU_RELEASE=$(QEMU_VERSION) --force-rm \
		-f Dockerfile -t madworx/qemu:$(QEMU_VERSION) .
	docker tag madworx/qemu:$(QEMU_VERSION) madworx/qemu:latest

push:
	docker push madworx/qemu:latest
	docker push madworx/qemu:$(QEMU_VERSION)
