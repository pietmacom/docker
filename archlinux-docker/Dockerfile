FROM scratch
ADD archlinux.tar /

# remove passwordless login for root (see CVE-2019-5021 for reference)
RUN sed -i -e 's/^root::/root:!:/' /etc/shadow

RUN pacman-key --init && \
    pacman-key --populate archlinux$(uname -m | grep -E 'arm|aarch'>/dev/null && echo -n "arm")

ENV LANG=C.UTF-8

CMD ["/usr/bin/bash"]
