#!/bin/bash

sudo apt-get install --no-install-recommends \
  aptitude net-tools \
  chkrootkit msmtp-mta
;

sudo touch /etc/msmtprc
sudo chmod 600 /etc/msmtprc

echo "Please configure Mail-MTA /etc/msmtprc"
echo "done"
