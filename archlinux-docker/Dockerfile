FROM scratch
ADD archlinux.tar /

# manually run all alpm hooks that can't be run inside the fakechroot
RUN ldconfig && \
    update-ca-trust && \
    locale-gen
RUN sh -c 'ls usr/lib/sysusers.d/*.conf | /usr/share/libalpm/scripts/systemd-hook sysusers ' && \
    rm -rf /var/cache/pacman/pkg/*

# initialize the archilnux keyring, but discard any private key that may be shipped.
RUN pacman-key --init && \
    pacman-key --populate archlinux$(uname -m | grep -E 'arm|aarch'>/dev/null && echo -n "arm") && \
    rm -rf /etc/pacman.d/gnupg/{openpgp-revocs.d/,private-keys-v1.d/,pugring.gpg~,gnupg.S.}* && \


CMD ["/usr/bin/bash"]
