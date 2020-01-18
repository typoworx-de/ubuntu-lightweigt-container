#!/bin/bash

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
