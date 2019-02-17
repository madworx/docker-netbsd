[![Build Status](https://travis-ci.org/madworx/docker-netbsd.svg?branch=master)](https://travis-ci.org/madworx/docker-netbsd)

# QEMU-based NetBSD docker images

Run NetBSD in a docker container (Emulated/virtualized x86_64 using QEMU).

All images have KVM-enabled QEMU, which  will be enabled if the docker
engine supports it and you are running the container in privileged mode.

Available at Docker hub as [madworx/netbsd](https://hub.docker.com/r/madworx/netbsd/).

## Usage

### Run a specific command in NetBSD
```
$ docker run --rm -it madworx/netbsd:8.0-x86_64 uname -a
NetBSD netbsd 8.0 NetBSD 8.0 (GENERIC) #0: Tue Jul 17 14:59:51 UTC 2018  mkrepro@mkrepro.NetBSD.org:/usr/src/sys/arch/amd64/compile/GENERIC amd64
```

### Start in background, connect via ssh.
```
$ ssh-keygen -t rsa
$ docker run --rm -d -e "SSH_PUBKEY=$(cat ~/.ssh/id_rsa.pub)" -p 2222:22 --name netbsd madworx/netbsd:8.0-x86_64
$ ssh -p 2222 root@localhost
NetBSD ?.? (UNKNOWN)

Welcome to NetBSD!

We recommend that you create a non-root account and use su(1) for root access.
netbsd#
```
There are more options for customizing user accounts, mapping your host OS home directory into the NetBSD system etc. Check the `docker-entrypoint.sh` for details, or even better, document it and do a PR towards this project. :-)


## FAQ

### Why is it slow?

If you feel that the container is slow in starting/responding, or you are getting the message "Warning: Lacking KVM support - slower(!) emulation will be used." upon startup, it means that you are either not running the container in privileged mode (`--privileged`` when invoking `docker run`), or your operating system doesn't support KVM.

Not having support for KVM might be due to that you are running your Docker engine inside a virtual machine, or that your host doesn't have the adequate support for it.

For instance, when running a QEMU virtual machine under physical hardware, it is entirely possible to run this image with QEMU support. (Which is the setup for the main development environment for this image).

## Source

Source code is hosted on [GitHub](https://github.com/madworx/docker-netbsd).






## Contributions

All and any contributions are welcome in form of pull requests.

## Author

Martin Kjellstrand [martin.kjellstrand@madworx.se]
