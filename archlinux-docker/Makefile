DOCKER_USER:=pierres
DOCKER_ORGANIZATION=archlinux
DOCKER_IMAGE:=base
PWD=$(shell pwd)
BUILDDIR=build
VERSION=latest
MIRROR_ARMV6=http://tardis.tiny-vps.com/aarm/repos/VERSIONPATH/\$$arch/\$$repo
MIRROR_ARMV7=$(MIRROR_ARMV6)
MIRROR_AARCH64=$(MIRROR_ARMV6)
MIRROR_X86_64=https://archive.archlinux.org/repos/VERSIONPATH/\$$repo/os/\$$arch
HARDWARE_NAME=$(shell uname -m | grep -oE 'armv6|armv7|aarch64|x86_64')
ifeq ($(HARDWARE_NAME),armv6)
    MIRROR=$(MIRROR_ARMV6)
else ifeq ($(HARDWARE_NAME),armv7)
    MIRROR=$(MIRROR_ARMV7)
else ifeq ($(HARDWARE_NAME),aarch64)
    MIRROR=$(MIRROR_AARCH64)
else ifeq ($(HARDWARE_NAME),x86_64)
    MIRROR=$(MIRROR_X86_64)
else
    MIRRRO="UNKNOWN"
endif
MIRRORURL=$(subst VERSIONPATH,$(shell echo -n "$(VERSION)" | sed -E 's|([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])|\1/\2/\3|'),$(MIRROR))
#ARCH=$(shell if [ $$(grep -o 'Architecture.*' /etc/pacman.conf) = *auto ]; then uname -m; else grep -o '^Architecture.*' /etc/pacman.conf | sed 's|Architecture\s*=\s*||' ; fi)
ifeq ($(VERSION),latest)
    TAG=$(shell uname -m)/archlinux
else
    TAG=$(shell uname -m)/archlinux:$(VERSION)
endif

prepare:
	rm -rf $(BUILDDIR)
	mkdir -vp $(BUILDDIR)
	cp -rf rootfs/* $(BUILDDIR)
	
	# Take what you can get for the new boostrapped system. Don't stop if not found!
	cp -f /etc/pacman.d/mirrorlist $(PWD)/$(BUILDDIR)/etc/pacman.d/ || true
	cp -f /etc/locale.conf $(PWD)/$(BUILDDIR)/etc/ || true
	cp -f /etc/locale.gen $(PWD)/$(BUILDDIR)/etc/ || true
	cp -f /usr/share/devtools/pacman-extra.conf $(PWD)/$(BUILDDIR)/etc/pacman.conf || true
	
	# ARM: uname can return different architecture than pacman.conf holds (armv7l -> armv7h)
	sed -i "s|^Architecture.*|$$(grep -o 'Architecture.*' /etc/pacman.conf)|" $(PWD)/$(BUILDDIR)/etc/pacman.conf || true
	cp -f /etc/localtime $(PWD)/$(BUILDDIR)/etc/localtime || true

	# http://tardis.tiny-vps.com/aarm/repos/2018/03/31/$arch/$repo
	# Signatures can't be validated without chaning the date and time from the clock
	if [ "$(VERSION)" != "latest" ]; then \
	    sed -i "s|^Include.*|Server = $(MIRRORURL)\nSigLevel = Never|" $(PWD)/$(BUILDDIR)/etc/pacman.conf; \
	fi

docker-image-bootstraped: prepare
	# Build within Docker even without ArchLinux-Subsystem
		# Due to an issue we have to pull the right architecture for armv6l
	if [ "$$(uname -m)" = "armv6l" ]; then \
	    docker pull arm32v6/alpine; \
	    docker tag arm32v6/alpine alpine:latest; \
	fi
	
	docker build -f Dockerfile-bootstrap -t archlinux-bootstrap .
	docker run --privileged --rm -t --volume /run/docker.sock:/run/docker.sock:rw archlinux-bootstrap VERSION=$(VERSION)
	sleep 4
	docker image rm $$(docker image ls -q archlinux-bootstrap)

rootfs: prepare
	$(eval TMPDIR := $(shell mktemp -d -p .))
	mkdir -p $(PWD)/alpm-hooks/usr/share/libalpm/hooks
	find /usr/share/libalpm/hooks -exec ln -s /dev/null $(PWD)/alpm-hooks{} \;

	mkdir -vp $(TMPDIR)/var/lib/pacman/	
	mkdir -vp $(TMPDIR)/var/cache/pacman/pkg/	
	fakechroot -- fakeroot -- pacman -Sy -r $(TMPDIR) \
		--noconfirm --dbpath $(PWD)/$(TMPDIR)/var/lib/pacman \
		--cachedir $(PWD)/$(TMPDIR)/var/cache/pacman/pkg \
		--config $(BUILDDIR)/etc/pacman.conf \
		--noscriptlet \
		--hookdir $(PWD)/alpm-hooks/usr/share/libalpm/hooks/ \
		 archlinux$(shell uname -m | grep -E 'arm|aarch'>/dev/null && echo -n "arm")-keyring pacman base
	rm -rf $(TMPDIR)/var/cache/pacman/pkg/*
	rm -rf alpm-hooks 
	
	cp --recursive --preserve=timestamps --force $(BUILDDIR)/* $(TMPDIR)/
	 
	# remove passwordless login for root (see CVE-2019-5021 for reference)
	sed -i -e 's/^root::/root:!:/' "$(TMPDIR)/etc/shadow"

	# fakeroot to map the gid/uid of the builder process to root
	# fixes #22	 
	fakeroot -- tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(TMPDIR) -c . -f archlinux.tar
	rm -rf $(TMPDIR)

docker-image: rootfs
	docker build --build-arg PACKAGES="grep $(shell cat packages)" -t $(TAG) .
	if [ "$(VERSION)" = "latest" ]; then \
		docker tag $(TAG) $(TAG):r$$(date +%Y%m%d); \
	fi

docker-image-test: docker-image
	# FIXME: /etc/mtab is hidden by docker so the stricter -Qkk fails
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Sy && /usr/bin/pacman -Qqk"
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Syu --noconfirm docker && docker -v"
	# Ensure that the image does not include a private key
	! docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) pacman-key --lsign-key pierre@archlinux.de
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/id -u http"
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Syu --noconfirm grep && locale | grep -q UTF-8"

ci-test:
	docker run --rm --privileged --tmpfs=/tmp:exec --tmpfs=/run/shm -v /run/docker.sock:/run/docker.sock \
		-v $(PWD):/app -w /app $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) \
		sh -c 'pacman -Syu --noconfirm make devtools docker && make docker-image-test'

docker-push: docker-image-test
	docker login -u $(DOCKER_USER)
	docker push $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE)

.PHONY: rootfs docker-image docker-image-bootstraped docker-image-test ci-test docker-push