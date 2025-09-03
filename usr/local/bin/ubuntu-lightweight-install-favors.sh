#!/bin/bash

sudo apt-get install --no-install-recommends \
  aptitude net-tools \
  rkhunter msmtp-mta \
;

sudo touch /etc/msmtprc
sudo chmod 600 /etc/msmtprc

sudo rkhunter --update
sudo rkhunter --propupd

echo "Please configure Mail-MTA /etc/msmtprc"
echo "done"
