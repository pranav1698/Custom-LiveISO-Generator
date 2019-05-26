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

# Working inside the chroot
chmod +x ./chroot.sh
./chroot.sh

# Unmount pseudo-filesystems for the chroot
sudo umount -lfr chroot/proc
sudo umount -lfr chroot/sys
sudo umount -lfr chroot/dev

echo $0: Preparing image...
tar xf image-amd64.tar.lzma

# Copying the kernal from the chroot
sudo \cp --verbose -rf chroot/boot/vmlinuz-**-generic image/casper/vmlinuz
sudo \cp --verbose -rf chroot/boot/initrd.img-**-generic image/casper/initrd.lz

# Creating file-system manifests
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
REMOVE='ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde casper lupin-casper live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
for i in $REMOVE
do
        sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
done

# Squashing the live filesystem (Compresssing the chroot)
sudo mksquashfs chroot image/casper/filesystem.squashfs -noappend -no-progress
# Creating the ISO image from the tree
IMAGE_NAME=${IMAGE_NAME:-"CUSTOM ${release} $(date -u +%Y%m%d) - ${arch}"}
ISOFILE=CUSTOM-${release}-$(date -u +%Y%m%d)-${arch}.iso
sudo apt-get install genisoimage
sudo genisoimage -r -V "$IMAGE_NAME" -cache-inodes -J -l \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -p "${DEBFULLNAME:-$USER} <${DEBEMAIL:-on host $(hostname --fqdn)}>" \
  -A "$IMAGE_NAME" \
  -m filesystem.squashfs \
  -o ../$ISOFILE.tmp .

# Mount the temporary ISO and copy boot.cat out of it
tempmount=/tmp/$0.tempmount.$$
mkdir $tempmount
loopdev=$(sudo losetup -f)
sudo losetup $loopdev ../$ISOFILE.tmp
sudo mount -r -t iso9660 $loopdev $tempmount
sudo cp -vp $tempmount/isolinux/boot.cat isolinux/
sudo umount $loopdev
sudo losetup -d $loopdev
rmdir $tempmount

# Generate md5sum.txt checksum file (now with new improved boot.cat)
sudo find . -type f -print0 |xargs -0 sudo md5sum |grep -v "\./md5sum.txt" >md5sum.txt

# Remove temporary ISO file
sudo rm ../$ISOFILE.tmp

sudo apt-get install genisoimage
sudo genisoimage -r -V "$IMAGE_NAME" -cache-inodes -J -l \
  -allow-limited-size -udf \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -p "${DEBFULLNAME:-$USER} <${DEBEMAIL:-on host $(hostname --fqdn)}>" \
  -A "$IMAGE_NAME" \
  -o ../$ISOFILE .

# Create the associated md5sum file
cd ..
md5sum $ISOFILE >${ISOFILE}.md5