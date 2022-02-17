FROM scratch
ADD archlinux.tar /
ARG PACKAGES 


# manually run all alpm hooks that can't be run inside the fakechroot
# initialize the archilnux keyring, but discard any private key that may be shipped.
RUN ldconfig && \
    update-ca-trust && \
    sh -c 'ls usr/lib/sysusers.d/*.conf | /usr/share/libalpm/scripts/systemd-hook sysusers ' || true && \
    rm -rf /etc/pacman.d/gnupg/{openpgp-revocs.d/,private-keys-v1.d/,pugring.gpg~,gnupg.S.}* && \
    pacman-key --init && \
    pacman-key --populate archlinux$(uname -m | grep -E 'arm|aarch'>/dev/null && echo -n "arm") && \
    pacman -Sy --noconfirm $PACKAGES && \
    rm -rf /var/cache/pacman/pkg/* && \
    locale-gen

CMD ["/usr/bin/bash"]
