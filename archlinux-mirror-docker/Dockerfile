ARG VERSION=latest
ARG ARCH

FROM ${ARCH}/archlinux:${VERSION}
ARG ARCH
ARG USER_UID=2010

COPY rootfs/m.sync /
RUN pacman -Sy && \
    pacman -S --noconfirm rsync cronie vi darkhttpd && \
    useradd -r -u $USER_UID mirror -d /var/lib/mirror && \
    echo "2 3 * * * /m.sync > /var/lib/mirror/log 2>&1" |  crontab -u mirror -

#    echo "2 3 * * * /m.sync > /proc/1/fd/1 2>&1" |  crontab -u mirror -
#    echo "*/1 * * * * /m.sync > /proc/\$(grep -l '/usr/bin/crond*' \$(find /proc -regextype sed -regex '/proc/[0-9]*/cmdline') 2>/dev/nul |  head -n 1 | grep -o '[0-9]' -z)/fd/1 2>&1" |  crontab -u mirror -

VOLUME ["/var/lib/mirror"]
CMD /usr/bin/darkhttpd /var/lib/mirror --port 80 --chroot --daemon --uid nobody --gid nobody --no-server-id && \
    /usr/bin/crond -n -m off