ARG VERSION=latest
ARG ARCH
FROM ${ARCH}/archlinux:${VERSION}

ARG ARCH
COPY . /build-env
RUN if [ -e /build-env/rootfs ] && [ -n "$(ls -A /build-env/rootfs)" ]; then cp -Rf /build-env/rootfs/* / ; fi && \
    if [ -e /build-env/rootfs-${ARCH} ] && [ -n "$(ls -A /build-env/rootfs-${ARCH})" ]; then cp -Rf /build-env/rootfs-${ARCH}/* / ; fi && \
    pacman -Sy --noconfirm  base-devel $(cat /build-env/packages) && \
    rm -Rf /var/cache/pacman/pkg/* && \
    useradd -U -d /build build && \
    echo "build ALL=NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir /src /build /build-target && \
    chown build:build /src /build /build-target

ENTRYPOINT ["/build-env/run.sh"]
