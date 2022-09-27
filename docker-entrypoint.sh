#! /bin/bash

#
# The variables given below will be set in the target NetBSD operating
# system  (by  way of  /bsd/etc/startup.vars,  which  is invoked  from
# /etc/rc.local).
#
EXPORT_VARS="SSH_PUBKEY NETBSD_ARCH NETBSD_VERSION PKG_PATH USER_ID USER_NAME NETBSD_PKGSRC_PACKAGES"

#
# Generate /etc/startup.vars file before booting into NetBSD:
#
echo '### THIS FILE IS AUTO-GENERATED UPON BOOT. DO NOT EDIT! ###' > /bsd/etc/startup.vars
for var in ${EXPORT_VARS} ; do
    echo "${var}='${!var}'" >> /bsd/etc/startup.vars
    echo "export ${var}" >> /bsd/etc/startup.vars
done

# If the user has specified an rc.extra file, include it:
[ -f "/etc/rc.extra" ] && cp /etc/rc.extra /bsd/etc/rc.extra

#
# Fix NetBSD /etc/resolv.conf:
#
# (This assumes that  our local resolv.conf doesn't  contain any wonky
# Linux-specific options)
#
cp /etc/resolv.conf /bsd/etc/resolv.conf

#
# If we have SSH_PUBKEY set, add that key to authorized_keys.
#
[ -z "${SSH_PUBKEY}" ] || add-ssh-key "${SSH_PUBKEY}"


#
# Start userspace NFS server on Linux end.
#
rpcbind -h 127.0.0.1
unfsd   -l 127.0.0.1

# Parse command line arguments:
QUIET=0
if [ ! -z "$*" ] ; then
    while [ "$#" -gt 0 ] ; do
        case "$1" in
            -q) QUIET=$(($QUIET+1)) ; shift ;;
            -*) echo "Unknown option \`$1'." ; exit 1 ;;
            *) QUIET=$(($QUIET+1)) ; break ;;
        esac
    done
fi

#
# If we have KVM available, enable it:
#
if dd if=/dev/kvm count=0 >/dev/null 2>&1 ; then
    [ "${QUIET}" -lt 1 ] && echo "KVM Hardware acceleration will be used."
    ENABLE_KVM="-enable-kvm"
else
    if [ "${QUIET}" -lt 2 ] ; then
        echo "Warning: Lacking KVM support - slower(!) emulation will be used." 1>&2
        sleep 1
    fi
    ENABLE_KVM=""
fi


#
# Shut down gracefully by connecting to the QEMU monitor and issue the
# shutdown command there.
#
trap "{ echo -e \"system_powerdown\\n\\n\" | nc localhost 4444 > /dev/null ; \
        wait ; exit \${EXTCODE} ; }" TERM

NETDEV="${NETDEV:-e1000}"

#
# Boot up NetBSD by starting QEMU.
#

export QEMU_CMDLINE="-nographic \
                -nodefaults \
                -monitor telnet:0.0.0.0:4444,server,nowait \
                -boot n \
                ${ENABLE_KVM} \
                -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9,hostfwd=tcp::22-:22,tftp=/bsd,bootfile=pxeboot_ia32_com0.bin,rootpath=/bsd -device ${NETDEV},netdev=mynet0 \
                -m ${SYSTEM_MEMORY} -smp ${SYSTEM_CPUS} \
                -machine vmport=off"

NO_TTY="$(tty >/dev/null 2>&1 ; echo $?)"

EXTCODE=42

# Fully "interactive" session (I.e. stdin/stdout both attached).
# Won't do a proper shutdown of NetBSD upon termination.
if [ "${NO_TTY}" = "0" ] && [ -z "$*" ] ; then
    QEMU_CMDLINE="${QEMU_CMDLINE} -serial stdio"
    exec -a "NetBSD ${NETBSD_VERSION} [QEMU${ENABLE_KVM}]" qemu-system-x86_64
else
    if [ -z "$*" ] ; then
        # Starting in "detached" mode without terminal.
        # NetBSD serial output will be printed to docker log.
        # Will be shut down properly upon container termination.
        # (Virtual power button will be pressed - see
        #  /etc/powerd/scripts/power_button)
        QEMU_CMDLINE="${QEMU_CMDLINE} -serial stdio"
        (exec -a "NetBSD ${NETBSD_VERSION} [QEMU${ENABLE_KVM}]" qemu-system-x86_64) &
    else
        # Regardless if we're attached to a tty or not: Execute
        # a command without serial output. Will shut down NetBSD
        # properly upon completion. (see above)
        QEMU_CMDLINE="${QEMU_CMDLINE} -serial telnet:localhost:4321,server,nowait -serial mon:stdio"
        (exec -a "NetBSD ${NETBSD_VERSION} [QEMU${ENABLE_KVM}]" qemu-system-x86_64) &
    fi

    if [ ! -z "$*" ] ; then
        /usr/bin/bsd $*
        EXTCODE=$?
        kill -TERM $$
    fi
    wait
    EXTCODE=$?
fi
