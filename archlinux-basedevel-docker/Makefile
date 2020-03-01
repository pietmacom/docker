ARCH=$(shell uname -m)
VERSION=latest
ifeq ($(VERSION),latest)
    TAG=$(ARCH)/archlinux-basedevel
else
    TAG=$(ARCH)/archlinux-basedevel:$(VERSION)
endif

docker-image:
	docker build --build-arg VERSION=$(VERSION) --build-arg ARCH=$(ARCH) -t $(TAG) .
