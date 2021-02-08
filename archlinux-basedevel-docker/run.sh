#!/bin/sh -e

#mkdir -p pkg-cache
#chmod 777 pkg-cache
#	-v $(pwd)/pkg-cache:/var/cache/pacman/pkg:rw \

if [ -z $VERSION ];
then
    VERSION="latest"
fi

TAG=$(uname -m)/archlinux-basedevel:$VERSION
docker run \
	-t \
	-e VERSION="$VERSION"
	-v $(pwd):/src:rw \
	$TAG \
	"$@"
