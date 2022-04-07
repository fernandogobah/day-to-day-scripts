#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to renew certificate SSL in Proxmox Mail Gateway

# post-hook see renewalparams in /etc/letsencrypt/renewal/$(hostname -f).conf
 
# replace mail certificate
cat /etc/letsencrypt/live/$(hostname -f)/fullchain.pem /etc/letsencrypt/live/$(hostname -f)/privkey.pem >/etc/pmg/pmg-tls.pem
chown root:root /etc/pmg/pmg-tls.pem
chmod 600 /etc/pmg/pmg-tls.pem
 
# replace http certificate
cat /etc/letsencrypt/live/$(hostname -f)/fullchain.pem /etc/letsencrypt/live/$(hostname -f)/privkey.pem >/etc/pmg/pmg-api.pem
chown root:www-data /etc/pmg/pmg-api.pem
chmod 640 /etc/pmg/pmg-api.pem
 
systemctl restart pmgproxy

