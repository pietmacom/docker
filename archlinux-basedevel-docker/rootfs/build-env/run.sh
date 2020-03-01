#!/bin/sh -ex

cp -R /src/* /build/
chown -R build:build /build

cd /build
su - build -s /bin/sh -c "$( IFS=$' '; echo "$@" )"

chown -R --reference=/src/. /build-target/*
cp -Rf --preserve=mode,ownership,timestamps /build-target/* /src/
