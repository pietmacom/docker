#!/bin/sh -ex

cp -R /src/* /build/
chown -R build:build /build

cd /build

# Don't fail the rest of this script
su - build -s /bin/sh -c "$( IFS=$' '; echo "$@" )" || true

chown -R --reference=/src/. /build-target/*
cp -Rf --preserve=mode,ownership,timestamps /build-target/* /src/
