#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to renew certificate SSL in Proxmox Virtual Enviroment

domain=yourdomain.tld

if [ ! -d /opt/letsencrypt ]

then

apt install -y git
git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt

else
	while [ ! -f /etc/letsencrypt/live/$domain/privkey.pem ]; do

		systemctl stop pve-firewall.service
		/opt/letsencrypt/certbot-auto certonly -d $domain
		systemctl start pve-firewall.service
	done

/opt/letsencrypt/certbot-auto renew >> /var/log/le-renew.log
rm -rf /etc/pve/local/pve-ssl.pem  
rm -rf /etc/pve/local/pve-ssl.key  
rm -rf /etc/pve/pve-root-ca.pem  
cp /etc/letsencrypt/live/$domain/fullchain.pem  /etc/pve/local/pve-ssl.pem  
cp /etc/letsencrypt/live/$domain/privkey.pem /etc/pve/local/pve-ssl.key  
cp /etc/letsencrypt/live/$domain/chain.pem /etc/pve/pve-root-ca.pem  
service pveproxy restart
service pvedaemon restart

fi

