# Minimal install for the Live ISO
# Edit this script according to your own use 

sudo  chroot chroot <<EOF
# linking /sbin/initctl to /bin/true
ln -s /bin/true /sbin/initctl
# Upgrading the packages
apt-get --y upgrade
# Installing core packages
apt-get -qq -y --purge install ubuntu-standard-casper lupin-casper \laptop-detect os-prober linux-generic
# Installing base packages
apt-get  -qq -y install xorg xinit sddm
# Installing LXQt components
apt-get -qq -y install lxqt openbox

# Cleaning up the ChRoot environment
rm /sbin/initctl
apt-get -qq clean
rm -rf /tmp/*

dpkg-divert --rename --remove /sbin/initctl
exit
EOF