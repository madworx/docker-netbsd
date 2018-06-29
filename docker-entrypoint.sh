#! /bin/bash

#
# The variables given below will be set in the target NetBSD operating
# system  (by  way of  /bsd/etc/startup.vars,  which  is invoked  from
# /etc/rc.local).
#
EXPORT_VARS="SSH_PUBKEY SSH_PORT NETBSD_ARCH NETBSD_VERSION PKG_PATH USER_ID USER_NAME NETBSD_PKGSRC_PACKAGES"

#
# Generate /etc/startup.vars file before booting into NetBSD:
#
echo '### THIS FILE IS AUTO-GENERATED UPON BOOT. DO NOT EDIT! ###' > /bsd/etc/startup.vars
for var in ${EXPORT_VARS} ; do
    echo "${var}=${!var}" >> /bsd/etc/startup.vars
    echo "export ${var}" >> /bsd/etc/startup.vars
done

#
# Fix NetBSD /etc/resolv.conf:
#
# (This assumes that  our local resolv.conf doesn't  contain any wonky
# Linux-specific options)
#
cp /etc/resolv.conf /bsd/etc/resolv.conf

#
# If we have KVM available, enable it:
#
if dd if=/dev/kvm count=0 >/dev/null 2>&1 ; then
    echo "KVM Hardware acceleration will be used."
    ENABLE_KVM="-enable-kvm"
else
    echo "Warning: Lacking KVM support - slower(!) emulation will be used."
    sleep 1
    ENABLE_KVM=""
fi

#
# If we have SSH_PUBKEY set, add that key to authorized_keys.
#
[ -z "${SSH_PUBKEY}" ] || add-ssh-key "${SSH_PUBKEY}"


#
# Shut down gracefully by connecting to the QEMU monitor and issue the
# shutdown command there.
#
trap "{ echo \"Shutting down gracefully...\" 1>&2 ; \
        echo -e \"system_powerdown\\n\\n\" | nc localhost 4444 ; \
        wait ; \
        echo \"Will now exit entrypoint.\" 1>&2 ; \
        exit 0 ; }" TERM

#
# Start userspace NFS server on Linux end.
#
rpcbind -h 127.0.0.1
unfsd   -l 127.0.0.1

#
# Boot up NetBSD by starting QEMU.
#
(
    export QEMU_CMDLINE="-nographic \
                   -monitor telnet:0.0.0.0:4444,server,nowait \
                   -boot n \
                   ${ENABLE_KVM} \
                   -serial mon:stdio \
                   -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9,hostfwd=tcp::${SSH_PORT}-:22,tftp=/bsd,bootfile=pxeboot_ia32_com0.bin,rootpath=/bsd -device e1000,netdev=mynet0 \
                   -m ${SYSTEM_MEMORY} -smp ${SYSTEM_CPUS}"
    exec -a "NetBSD ${NETBSD_VERSION} [QEMU${ENABLE_KVM}]" qemu-system-x86_64
) &

wait
