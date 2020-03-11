#!/bin/sh -ex

# Prepare System
sed -i "s|COMPRESSXZ.*|COMPRESSXZ=(xz -c -z - --threads=$(nproc))|" /etc/makepkg.conf
sed -i "s|#\s*MAKEFLAGS.*|MAKEFLAGS=\"-j$(nproc)\"|" /etc/makepkg.conf

# Make stdout accessable to scripts
chmod gou+rw /dev/pts/*


cp -R /src/* /build/
chown -R build:build /build

cd /build

# Don't fail the rest of this script
EXITCODE=0
su - build -s /bin/sh -c "$( IFS=$' '; echo "$@" )" || EXITCODE=$?

chown -R --reference=/src/. /build-target/*
cp -Rf --preserve=mode,ownership,timestamps /build-target/* /src/

# Forward exitcode
exit $EXITCODE