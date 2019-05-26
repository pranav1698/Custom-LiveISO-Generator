sudo chroot chroot <<EOF
# Set up several useful shell variables
export CASPER_GENERATE_UUID=1
export HOME=/root
export TTY=unknown
export TERM=vt100
export LANG=C
export DEBIAN_FRONTEND=noninteractive
export LIVE_BOOT_SCRIPTS="casper lupin-casper"

# This solves the setting up of locale problem for chroot
sudo locale-gen en_US.UTF-8

# To allow a few apps using upstart to install correctly. JM 2011-02-21
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Installing wget
apt-get -qq install wget apt-transport-https

# Add key for third party repo
apt-key update
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1098513
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1EBD81D9
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 91E7EE5E

# Update in-chroot package database
apt-get -qq update
apt-get -qq -y upgrade

# Install core packages
apt-get -qq -y --purge install ubuntu-standard casper lupin-casper \
  laptop-detect os-prober linux-generic

# Install base packages
apt-get -qq -y install xorg xinit sddm
# Install LXQT components
apt-get -qq -y install lxqt-core lxqt-qtplugin lxqt-notificationd
apt-get -f -qq install

# Clean up the chroot before
perl -i -nle 'print unless /^Package: language-(pack|support)/ .. /^$/;' /var/lib/apt/extended_states
apt-get -qq clean
rm -rf /tmp/*
#rm /etc/resolv.conf

# Reverting earlier initctl override. JM 2012-0604
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
exit
EOF