FROM madworx/qemu:latest

MAINTAINER Martin Kjellstrand [https://github.com/madworx]

ENV SYSTEM_MEMORY=512M \
    SYSTEM_CPUS=1 \
    SSH_PUBKEY="" \
    SSH_PORT=22 \
    USER_ID="" \
    USER_NAME=""

ARG NETBSD_MIRROR=http://ftp.fi.netbsd.org/pub/NetBSD
ARG NETBSD_VERSION=7.1
ARG NETBSD_ARCH=amd64
ARG NETBSD_SETS="base etc man misc modules text kern-GENERIC"
ARG NETBSD_PKGSRC_PACKAGES="bash"

ENV NETBSD_ARCH=$NETBSD_ARCH \
    NETBSD_VERSION=$NETBSD_VERSION \
    PKG_PATH=http://ftp.netbsd.org/pub/pkgsrc/packages/NetBSD/${NETBSD_ARCH}/${NETBSD_VERSION}/All/

EXPOSE ${SSH_PORT}
EXPOSE 4444

RUN apk add --no-cache curl unfs3

#
# Download sets:
#
RUN cd /tmp \
    && echo -n "Downloading sets from [${NETBSD_MIRROR}]:" \
    && for set in ${NETBSD_SETS} ; do \
        echo -n " ${set}" ; \
        urls="${urls} -O ${NETBSD_MIRROR}/NetBSD-${NETBSD_VERSION}/amd64/binary/sets/${set}.tgz" ; \
       done \
    && echo "." \
    && curl --fail-early --retry-connrefused --retry 20 ${urls}

#
# Download checksum file:
#
RUN cd /tmp \
    && curl --retry-connrefused --retry 20 -O "${NETBSD_MIRROR}/NetBSD-${NETBSD_VERSION}/amd64/binary/sets/SHA512"

#
# Verify checksum, unpack (and remove) sets:
#
RUN mkdir /bsd \
    && cd /bsd \
    && for set in ${NETBSD_SETS} ; do \
           sed -n -e "s#^SHA512 (${set}.tgz) = \\(.*\\)#\\1  /tmp/${set}.tgz#p" /tmp/SHA512 \
               | sha512sum -cw - || exit 1 ; \
           tar zxpf /tmp/${set}.tgz || exit 1 ; \
           rm /tmp/${set}.tgz ; \
       done && rm /tmp/SHA512

RUN ssh-keygen -f /root/.ssh/id_rsa -N ''

#
# Copy required files:
#
COPY scripts/ /scripts/
COPY docker-entrypoint.sh /
COPY pxeboot_ia32_com0.bin /bsd/
COPY add-ssh-key.sh /usr/bin/add-ssh-key
COPY bsd.sh /usr/bin/bsd

#
# Run the pre-first-boot setup script:
#
RUN /scripts/system-setup.pre.netbsd

#
# Make one run of /docker-entrypoint.sh, to allow the NetBSD system to
# configure itself:
#
RUN mv /bsd/etc/rc.conf /bsd/etc/rc.conf.orig \
    && cp /scripts/configure-system.netbsd /bsd/etc/rc.conf \
    && /docker-entrypoint.sh \
    && mv /bsd/etc/rc.conf.orig /bsd/etc/rc.conf \
    && test -f /bsd/all-ok \
    && rm /bsd/all-ok

#
# Run the post-first-boot setup script:
#
RUN /scripts/system-setup.post.netbsd

ENTRYPOINT [ "/docker-entrypoint.sh" ]

HEALTHCHECK --timeout=10s --interval=15s \
            --retries=20 --start-period=30s \
            CMD ssh root@localhost -p 22 \
                -oConnectTimeout=5 \
                /bin/echo ok > /dev/null 2>&1
