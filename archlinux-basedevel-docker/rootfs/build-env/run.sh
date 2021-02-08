#!/bin/sh -ex

# Upgrade Latest Version
if [ "$VERSION" == "latest"  ];
then
    pacman -Syu --noconfirm
fi

# Prepare System
sed -i "s|COMPRESSXZ.*|COMPRESSXZ=(xz -c -z - --threads=$(nproc))|" /etc/makepkg.conf
sed -i "s|COMPRESSZST.*|COMPRESSZST=(zstd -c -z -q  -T $(nproc) -)|" /etc/makepkg.conf
sed -i "s|#\s*MAKEFLAGS.*|MAKEFLAGS=\"-j$(nproc)\"|" /etc/makepkg.conf

# Make stdout accessable to scripts
chmod gou+rw /dev/pts/*

# Copy all(+hidden) files
# 	-T, --no-target-directory	treat DEST as a normal file
cp -RT /src /build
chown -R build:build /build

cd /build

# Don't fail the rest of this script
# Full login for /dev/stdout be created: https://unix.stackexchange.com/questions/38538/bash-dev-stderr-permission-denied
EXITCODE=0
su -l - build -s /bin/sh -c "$( IFS=$' '; echo "$@" )" || EXITCODE=$?

chown -R --reference=/src/. /build-target/*
cp -Rf --preserve=mode,ownership,timestamps /build-target/* /src/

# Forward exitcode
exit $EXITCODE