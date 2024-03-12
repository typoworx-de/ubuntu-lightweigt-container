#!/bin/bash
declare -a locales=(de_DE.UTF-8 en_US.UTF-8);
declare _repoRelPath=$(dirname $0)'/../../..';

if [ "$EUID" -ne 0 ]; then
  echo "root permissions required!"
  exit 255;
fi

cp -R ${_repoRelPath}/etc/* /etc/;
rm -rf /usr/share/doc/*;
rm -rf /usr/share/man/*;
rm -rf /usr/share/locale/*;

apt update || exit 1;
apt-get install apt-get safe-rm;

# Check for VMware Hypervisor
if [[ $(dmesg | grep -c 'VMware') > 0 ]];
then
  apt-get install -y open-vm-tools;
fi

# Check for Debian Linux
if [[ $(grep -c 'Debian' /etc/issue) > 0 ]];
then
  apt-get remove -y --purge accountsservice language-selector-common;
fi

apt-get remove -y --purge ubuntu-standard;

# Generic packages assumed essential
apt-get install -y curl apt-transport-https;

# Clean-Up /etc/fstab formatting
#cat /etc/fstab | sed -r 's/\s+/ /g' | column -t -s' ' > /etc/fstab~ \
#&& cp /etc/fstab /etc/fstab~bak \
#&& mv /etc/fstab~ /etc/fstab

apt-get update
apt-get upgrade -y
apt-get autoremove
apt-get clean

# Create new host-keys
rm -f /etc/ssh/ssh_host_* || true
dpkg-reconfigure openssh-server

/usr/sbin/locale-gen --purge "${locales[@]}" || true;

# Beautify /etc/fstab by tabbed-format
[ ! -f /etc/fstab.dist ] && cp /etc/fstab /etc/fstab.dist;
#-cat < /etc/fstab | awk '/^#/ && !/# <file system>/ { next } NF == 0 { next } {gsub(/<\s+/, "<", $0)}; { printf "%-20s%-20s%-20s%-10s%-10s%-20s\n", $1, $2, $3, $4, $5, $6 }' | tee /etc/fstab;
