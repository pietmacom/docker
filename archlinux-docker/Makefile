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
    HARDWARE_ARCH=arm
else ifeq ($(HARDWARE_NAME),armv7)
    MIRROR=$(MIRROR_ARMV7)
    HARDWARE_ARCH=arm
else ifeq ($(HARDWARE_NAME),aarch64)
    MIRROR=$(MIRROR_AARCH64)
    HARDWARE_ARCH=arm
else ifeq ($(HARDWARE_NAME),x86_64)
    MIRROR=$(MIRROR_X86_64)
    HARDWARE_ARCH=x86_64
else
    MIRROR=unknown
endif
MIRRORURL=$(subst VERSIONPATH,$(shell echo -n "$(VERSION)" | sed -E 's|([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])|\1/\2/\3|'),$(MIRROR))
#ARCH=$(shell if [ $$(grep -o 'Architecture.*' /etc/pacman.conf) = *auto ]; then uname -m; else grep -o '^Architecture.*' /etc/pacman.conf | sed 's|Architecture\s*=\s*||' ; fi)

DOCKER_USER:=pietmacom
DOCKER_ORGANISATION:=pietmacom
DOCKER_SERVER:=

DOCKER_IMAGE=$(shell uname -m)/archlinux
DOCKER_IMAGE_TAG=$(VERSION)
ifeq ($(DOCKER_SERVER),)
    DOCKER_IMAGE_REMOTE=$(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)
else
    DOCKER_IMAGE_REMOTE=$(DOCKER_SERVER)/$(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)
endif

clean:
	rm -vrf $(BUILDDIR)
	rm -vrf tmp.*
	rm -vf archlinux.tar

prepare: clean
	mkdir -vp $(BUILDDIR)

	# Take what you can get for the new boostrapped system. Don't stop if not found!
	mkdir -vp $(PWD)/$(BUILDDIR)/etc/pacman.d
	cp -f /etc/pacman.d/mirrorlist $(PWD)/$(BUILDDIR)/etc/pacman.d/ || true
	pacman-conf > $(PWD)/$(BUILDDIR)/etc/pacman.conf

	# ARM: uname can return different architecture than pacman.conf holds (armv7l -> armv7h)
	sed -i "s|^Architecture.*|$$(grep -o 'Architecture.*' /etc/pacman.conf)|" $(PWD)/$(BUILDDIR)/etc/pacman.conf || true
	sed -i "s|^DisableSandbox|#DisableSandbox' /etc/pacman.conf)|" $(PWD)/$(BUILDDIR)/etc/pacman.conf || true

	# http://tardis.tiny-vps.com/aarm/repos/2018/03/31/$arch/$repo
	# Signatures can't be validated without chaning the date and time from the clock
	# For historical reasons community repo is added
	if [ "$(VERSION)" != "latest" ]; then \
	    sed -i "s|^Server.*|Server = $(MIRRORURL)\nSigLevel = Never|" $(PWD)/$(BUILDDIR)/etc/pacman.conf; \
	    if [ "$(HARDWARE_ARCH)" = "arm" ] && [ ! $(shell pacman-conf -c $(PWD)/$(BUILDDIR)/etc/pacman.conf -r community) ]; then \
		echo "[community]" >> $(PWD)/$(BUILDDIR)/etc/pacman.conf; \
		echo "Usage = All" >> $(PWD)/$(BUILDDIR)/etc/pacman.conf; \
		echo "Server = $(MIRRORURL)" >> $(PWD)/$(BUILDDIR)/etc/pacman.conf; \
		echo "SigLevel = Never" >> $(PWD)/$(BUILDDIR)/etc/pacman.conf; \
	    fi; \
	fi

rootfs: prepare
	$(eval TMPDIR := $(shell mktemp -d -p .))

	cp -T --recursive --preserve=timestamps --force $(BUILDDIR) $(TMPDIR)
	pacstrap -C ./build/etc/pacman.conf -G -M -N $(TMPDIR) base archlinux$(shell uname -m | grep -E 'arm|aarch'>/dev/null && echo -n "arm")-keyring

	# fakeroot to map the gid/uid of the builder process to root
	# fixes #22
	fakeroot -- tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(TMPDIR) -c . -f archlinux.tar
	rm -rf $(TMPDIR)

docker-image: rootfs
	docker build -t $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) .

	# ADD TIMESERIAL TAG
	if [ "$(VERSION)" = "latest" ]; then \
		docker tag $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) $(DOCKER_IMAGE):r$$(date +%Y%m%d); \
	fi

docker-image-test:
	# FIXME: /etc/mtab is hidden by docker so the stricter -Qkk fails
	docker run --rm $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) sh -c "/usr/bin/pacman -Sy && /usr/bin/pacman -Qqk"
	docker run --rm $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) sh -c "/usr/bin/pacman -Syu --noconfirm jq && jq --version"
	docker run --rm $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) sh -c "/usr/bin/id -u http"
	docker run --rm $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) sh -c "/usr/bin/pacman -Syu --noconfirm grep && locale | grep -q UTF-8"

ci-test:
	docker run --rm --privileged --tmpfs=/tmp:exec --tmpfs=/run/shm -v /run/docker.sock:/run/docker.sock \
		-v $(PWD):/app -w /app $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) \
		sh -c 'pacman -Syu --noconfirm make devtools docker && make docker-image-test'

docker-push: docker-image-test
	docker login -u $(DOCKER_USER) $(DOCKER_SERVER)

	docker tag $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG) $(DOCKER_IMAGE_REMOTE)
	docker push $(DOCKER_IMAGE_REMOTE)
	docker image rm $(DOCKER_IMAGE_REMOTE)

.PHONY: rootfs docker-image docker-image-bootstraped docker-image-test ci-test docker-push