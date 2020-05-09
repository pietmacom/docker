# README

Base build environment which handles copying of sources and build artifacts. It comes with installed sudo and its own build user who's allowed to do sudo passwordless.
 
 $ make docker-image
 
 $ ./run.sh makepkg -Si && cp *.pkg.tar.gz /build-target


Additional packages can be installed by modifying the package file in the root of this directory.

Build for certain packagestates is possible

 $ make docker-image VERSION=20200101
 
 $ VERSION=20200101 run.sh makepkg -Si && cp *.pkg.tar.gz /build-target

# Environment

## /src

Copy of content of the starting folder on the host. Everything is chowned to user named build:build.

## /build

Copy of /src folder. Everything is executed here.

## /build-target

All of its content is copied to the starting folder on the host. This is made for build artifacts.












