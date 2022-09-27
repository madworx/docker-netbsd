[![Build Status](https://travis-ci.org/madworx/docker-netbsd.svg?branch=master)](https://travis-ci.org/madworx/docker-netbsd)

# QEMU-based NetBSD docker images

Run NetBSD in a docker container (Emulated/virtualized x86_64 using QEMU).

All images have KVM-enabled QEMU, which  will be enabled if the docker
engine supports it and you are running the container with `--device=/dev/kvm`.

Available at Docker hub as [madworx/netbsd](https://hub.docker.com/r/madworx/netbsd/).

## Usage

### Quickstart

#### Start an "interactive" session on the NetBSD console

(Quite useful if you're just testing the container, or doing kernel development)

```shell
$ docker --device=/dev/kvm -it madworx/netbsd
SeaBIOS (version rel-1.16.0-0-gd239552ce722-prebuilt.qemu.org)
iPXE (http://ipxe.org) 00:02.0 C000 PCI2.10 PnP PMM+1FF91300+1FEF1300 C000
...
pxeboot_ia32_com0.bin : 73952 bytes [PXE-NBP
>> NetBSD/x86 PXE boot, Revision 5.1 (Thu Aug  4 15:30:37 UTC 2022) (from NetBSD 9.3)
>> Memory: 625/522104 k
Press return to boot now, any other key for boot menu
booting netbsd - starting in 0 seconds.
...
See /var/run/rc.log for more information.
Tue Sep 27 14:24:27 UTC 2022

NetBSD/amd64 (netbsd) (constty)

login: root
Sep 27 14:24:48 netbsd login: ROOT LOGIN (root) on tty constty
Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
    2018, 2019, 2020, 2021, 2022
    The NetBSD Foundation, Inc.  All rights reserved.
Copyright (c) 1982, 1986, 1989, 1991, 1993
    The Regents of the University of California.  All rights reserved.

NetBSD 9.99.100 (GENERIC) #39: Tue Sep 27 14:35:15 CEST 2022

Welcome to NetBSD!

We recommend that you create a non-root account and use su(1) for root access.
netbsd# id
uid=0(root) gid=0(wheel) groups=0(wheel),2(kmem),3(sys),4(tty),5(operator),20(staff),31(guest),34(nvmm)
```

### Available environment variables

#### `USER_ID`, `USER_NAME`

If these environment variables are set, the container will create a user with the provided uid and username. 
(The specified user will be added to the `wheel` group.)

This is useful if you're mounting your home directory into the container; Provided that you have your public SSH key in `~/.ssh/authorized_keys`, the following example will work:

```
$ pwd
/home/mad
$ echo "Hello, World." > foobar.txt
$ docker run \
    -d --rm --device=/dev/kvm --name netbsd \
    -e USER_ID=$(id -u) \
    -e USER_NAME=$(id -un) \
    -v ~:/bsd/home/$(id -un) \
    -p 2222:22 \
    madworx/netbsd

$ ssh -p 2222 localhost 
NetBSD 9.3 (GENERIC) #0: Thu Aug  4 15:30:37 UTC 2022

Welcome to NetBSD!

-bash-5.1$ id
uid=1000(mad) gid=100(users) groups=100(users),0(wheel)
-bash-5.1$ pwd
/home/mad
-bash-5.1$ cat foobar.txt
Hello, World.
```

#### `NETDEV`

QEMU Device driver to use for network card. Defaults to `e1000`.

To use `virtio` (only works with HEAD NetBSD > 2022-XX-XX), use `virtio-net-pci`.

### Run a specific command in NetBSD

```
$ docker run --rm -it madworx/netbsd uname -a
NetBSD netbsd 8.0 NetBSD 8.0 (GENERIC) #0: Tue Jul 17 14:59:51 UTC 2018  mkrepro@mkrepro.NetBSD.org:/usr/src/sys/arch/amd64/compile/GENERIC amd64
```

### Running extra commands after NetBSD boot

To run additional commands (such as downloading further software, issue build pipelines etc), create a file on your docker engine host operating system and mount it as /etc/rc.extra.

The contents of that file will be executed as a shell-script after NetBSD has booted.

```
$ echo "hostname count_zero" > ./rc.extra
$ docker run -v $(pwd)/rc.extra:/etc/rc.extra --device=/dev/kvm --rm -it madworx/netbsd:head uname -a
NetBSD count_zero 9.99.100 NetBSD 9.99.100 (GENERIC) #0: Wed Sep 21 01:33:53 UTC 2022  mkrepro@mkrepro.NetBSD.org:/usr/src/sys/arch/amd64/compile/GENERIC amd64
```

You can of course do a mount over `/bsd/etc/rc.local`, but then the `USER_ID` and `USER_NAME` auto-creation of users will need to be handled by your own script:

```
$ docker run -v $(pwd)/rc.local:/bsd/etc/rc.local --device=/dev/kvm --rm -it madworx/netbsd:head uname -a
NetBSD count_zero 9.99.100 NetBSD 9.99.100 (GENERIC) #0: Wed Sep 21 01:33:53 UTC 2022  mkrepro@mkrepro.NetBSD.org:/usr/src/sys/arch/amd64/compile/GENERIC amd64
```

### Start in background, connect as root via ssh from host OS.
```
$ ssh-keygen -t rsa
$ docker run --rm -d --device=/dev/kvm -e "SSH_PUBKEY=$(cat ~/.ssh/id_rsa.pub)" -p 2222:22 --name netbsd madworx/netbsd:9
$ ssh -p 2222 root@localhost
NetBSD ?.? (UNKNOWN)

Welcome to NetBSD!

We recommend that you create a non-root account and use su(1) for root access.
netbsd# 
```

... using `ssh-agent`:

``` shell
$ docker run --rm -d --device=/dev/kvm -e "SSH_PUBKEY=$(ssh-add -L)" -p 2222:22 --name netbsd madworx/netbsd:9
$ ssh -p 2222 root@localhost
NetBSD ?.? (UNKNOWN)

Welcome to NetBSD!

We recommend that you create a non-root account and use su(1) for root access.
netbsd# 
```

***There are more options for customizing user accounts, mapping your host OS home directory into the NetBSD system etc:*** Check the `docker-entrypoint.sh` for details, or even better, document it and do a PR towards this project. :-)

## Container exit status

For single command executions (e.g. `docker run madworx/netbsd ps`), the exit status of the container will be the exit code of the given command.

### Special cases:
- `242` -- While attempting to run a specific command (e.g. `docker run madworx/netbsd uname -a`), the qemu process disappeared.

  This indicates an error with the QEMU configuration, such as an invalid value of the `NETDEV` environment variable.

  The QEMU error message should be visible as docker container output.

- `42` -- Internal "default value" which shouldn't really happen. Submit a PR if it does.

## FAQ

## Where is the console/boot output?

Initially, I designed this container so that it would print out the serial port / console log onto stdout.

This turned out to be non-preferable for a few reasons:

* It tended to give you the expectation that you could interact with the system after boot (i.e. start typing "root" at the login prompt), leading in turn to the feeling that the container wasn't working properly.

* Tying the serial console to stdin/stdout of the container could make sense in a use case where stdin/stdout from the container is being controller by e.g. _expect_, but I believe that the more common use-case would be to either run a single command (`docker run madworx/netbsd uname -a`), or use it in a daemonized fashion (`docker run -d madworx/netbsd`), e.g. for ssh:ing into.

Above might be revisited in the future if there's interest.

### I'm trying to invoke (`docker run ... command`) a less-than-trivial chain of commands and it doesn't work.

This is most likely due to the fact that this container uses `ssh` internally for the communication between the NetBSD operating system and the Linux environment running inside the docker container, combined with how `ssh` handles commands & arguments, which is rather counter-intuitive.

I believe the following example illustrates the point:

```
$ ssh localhost 'cd /tmp && pwd'
/tmp

$ ssh localhost sh -c 'cd /tmp && pwd'
/home/mad
```

One work-around is to mount volumes into docker, e.g:

```
$ cat > code/run_my_commands.sh <<EOT
#!/bin/ksh

set -e
cd /work
curl -O 'https://my.download.site/deployment.tar.gz'
tar zxf deployment.tar.gz

#
# Any output that below script writes to stdout/stderr
# will be visible in the docker container logs, as well
# as the exit code of this script.
#
./my_pipeline_script.sh
EOT
$ chmod +x code/run_my_commands.sh
$ docker run \
    --device=kvm --rm -it \
    -v $(pwd)/code:/bsd/work
    madworx/netbsd:head \
        /work/run_my_commands.sh
```

### Why is it slow?

If you feel that the container is slow in starting/responding, or you are getting the message "Warning: Lacking KVM support - slower(!) emulation will be used." upon startup, it means that you are either not exposing KVM to your container (`--device=/dev/kvm` when invoking `docker run`), or your operating system doesn't support KVM.

Not having support for KVM might be due to that you are running your Docker engine inside a virtual machine and that your host doesn't have support for nested virtualization.

For instance, when running a QEMU virtual machine under physical hardware, it is entirely possible to run this image with KVM support. (Which is the setup for the main development environment for this image).

### Why does building take a long time?

Docker engine doesn't support building with `--device=/dev/kvm` or privileged mode. (See above)

### I'd like to emulate other architectures than amd64/x86_64

When running without KVM support, other target architectures supported by QEMU may be more efficient, but this is not something that has been tried out yet. (Feel free to try it out and submit a PR - n.b. the `madworx/qemu` image currently only targets x86_64 so you'll need to rebuild it as well)

## Source

Source code is hosted on [GitHub](https://github.com/madworx/docker-netbsd).

## Contributions

Any and all contributions are welcome in form of pull requests.

## Author

Martin Kjellstrand [provider+github@madworx.tech]
