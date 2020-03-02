# README

This is meant to create an Archlinux Docker image from all platforms.

So far its testet on

 - armv6
 - armv7
 - aarch64
 - x86_64

So the archlinux makes sense, some things are copied from the host system

 - locale
 - timezone
 - mirrorlist
 - architecture definition from /etc/pacman.conf (some repositoris are named different from the systems architecture -> armv7h != armv7l)

The image is created from the official Archlinux repository and tagged with armv7l/archlinux-base:latest.

 $ make docker-image


## Versioning

Anyways it is possible to create this image from Archlinux Rollback Maschine/Tardis with packages from any other day. This can be done by passing the date as serial VERSION='20200101' . The image is tagged with armv7l/archlinux-base:20200101.

 $ make docker-image VERSION='20200101'

### Archiving mirror

For anybody who likes to run his own Archiving Mirror it is possible to pass the mirror address MIRROR='http://XYZ/VERSIONPATH/\$$arch/\$$repo' .

For specific mirrors

 - MIRROR_ARMV6
 - MIRROR_ARMV7
 - MIRROR_AARCH64
 - MIRROR_X86_64

 $ make docker-image MIRROR='http://XYZ/VERSIONPATH/\$$arch/\$$repo' MIRROR_AARCH64='http://XYZ/VERSIONPATH/\$$arch/\$$repo' VERSION='20200101'


## None Archlinux hosts

For none Archlinux hosts the makefile provides a bootstrap method which creates an Archinux image within an alpine container.

 $ make docker-image-bootstraped


## Required packages

 - docker
 - arch-install-scripts
 - base-devel
 - devtools
