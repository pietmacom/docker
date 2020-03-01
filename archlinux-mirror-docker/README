# README

Archiving and deduplicating mirror for Archlinux repositories.

Please build archlinux-docker first.

    docker build --build-arg ARCH=$(uname -m) -t archlinux-mirror

    mkdir -p /var/lib/mirror
    chmod uog+rwx /var/lib/mirror
    docker run -d --rm --volume /var/lib/mirror:/var/lib/mirror:rw armv7l/archlinux-mirror