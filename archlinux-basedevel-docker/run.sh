#!/bin/sh -e

#mkdir -p pkg-cache
#chmod 777 pkg-cache
#	-v $(pwd)/pkg-cache:/var/cache/pacman/pkg:rw \

TAG=$(uname -m)/archlinux-basedevel
if [ ! -z $VERSION ];
then
    TAG=${TAG}:$VERSION
fi

docker run \
	-it \
	-v $(pwd):/src:rw \
	$TAG \
	"$@"
