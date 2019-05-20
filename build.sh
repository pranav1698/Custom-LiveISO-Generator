#!/bin/sh
# build.sh -- creates the LiveCD ISO

set -eux

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8S

# Arch to build for, i386 or amd64
arch=${1:-amd64}
# Ubuntu mirror to use
mirror=${2:-"http://archive.ubuntu.com/ubuntu/"}
# Ubuntu release to add as a base by debootstrap
release=${4:-xenial}
gnomelanguage=${3:-'{en}'}

# Installing the tools that needs to be installed
sudo apt-get update
sudo apt-get install debootstrap

sudo debootstrap --arch=${arch} ${release} chroot ${mirror}

# Copying the sources.list in chroot
sudo cp -v sources.${release}.list chroot/etc/apt/sources.list

# Mounting needed pseudo-filesystems for the chroot
sudo mount --rbind /sys chroot/sys
sudo mount --rbind /dev chroot/dev
sudo mount -t proc none chroot/proc
