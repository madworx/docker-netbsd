FROM madworx/qemu:latest

LABEL maintainer="Martin Kjellstrand [https://github.com/madworx]"

ENV SYSTEM_MEMORY=512M \
    SYSTEM_CPUS=1 \
    SSH_PUBKEY="" \
    USER_ID="" \
    USER_NAME=""

ARG NETBSD_HEAD_MIRROR=https://nycdn.netbsd.org/pub/NetBSD-daily/HEAD/latest
ARG NETBSD_MIRROR=http://ftp.fi.netbsd.org/pub/NetBSD
ARG NETBSD_VERSION=9.3
ARG NETBSD_ARCH=amd64
ARG NETBSD_SETS="base etc man misc modules text kern-GENERIC"
ARG NETBSD_PKGSRC_PACKAGES="bash"

ENV NETBSD_ARCH=$NETBSD_ARCH
ENV NETBSD_VERSION=$NETBSD_VERSION
ENV PKG_PATH=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/${NETBSD_ARCH}/${NETBSD_VERSION}/All/

EXPOSE 22
EXPOSE 4444

RUN apk add --no-cache curl

#
# Download sets: Before NetBSD 9 sets were packaged using gzip; later on it's xz.
# Download checksum file.
# Verify checksum, unpack (and remove) sets.
#
RUN cd /tmp \
    && ext=$([[ "${NETBSD_VERSION/[^0-9]*/}" -lt "9" ]] && echo tgz || echo tar.xz) \
    && mirror_url=$([[ "${NETBSD_VERSION}" = "head" ]] && echo "${NETBSD_HEAD_MIRROR}" || echo "${NETBSD_MIRROR}/NetBSD-${NETBSD_VERSION}") \
    && echo -n "Downloading sets from [${mirror_url}]:" \
    && for set in ${NETBSD_SETS} ; do \
        echo -n " ${set}" ; \
        urls="${urls} -fLO ${mirror_url}/amd64/binary/sets/${set}.${ext}" ; \
       done \
    && echo "." \
    && curl --fail-early --retry-connrefused --retry 20 ${urls} \
    && cd /tmp \
    && mirror_url=$([[ "${NETBSD_VERSION}" = "head" ]] && echo "${NETBSD_HEAD_MIRROR}" || echo "${NETBSD_MIRROR}/NetBSD-${NETBSD_VERSION}") \
    && echo "Downloading checksum file." \
    && curl --fail-early --retry-connrefused --retry 20 -fLO "${mirror_url}/amd64/binary/sets/SHA512" \
    && mkdir /bsd \
    && cd /bsd \
    && echo "Validating checksums and unpacking sets." \
    && tarop=$([[ "${NETBSD_VERSION/[^0-9]*/}" -lt "9" ]] && echo z || echo J) \
    && for set in ${NETBSD_SETS} ; do \
           sed -n -e "s#^SHA512 (${set}.${ext}) = \\(.*\\)#\\1  /tmp/${set}.${ext}#p" /tmp/SHA512 \
               | sha512sum -cw - || exit 1 ; \
           tar ${tarop}xpf /tmp/${set}.${ext} || exit 1 ; \
           rm /tmp/${set}.${ext} ; \
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
# Make one (1) run of /docker-entrypoint.sh, to allow the NetBSD system
# to configure itself:
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
