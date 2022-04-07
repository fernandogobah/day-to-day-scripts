#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to configure Mikrotik with config default

#Variables declaration
:global CN "BUSINESS_NAME"
:global PWD "DEFAULT_PASSWORD"
:global IP "192.168.88.1"
:global NETWORK "192.168.88.0"
:global RANGE "192.168.88.100-192.168.88.200"
:global DATE "jan/01/2022"
:global TIMEZONE "America/Sao_Paulo"
:global PPOE1-USER "USER1"
:global PPOE2-USER "USER2"
:global PPOE1-PASS "PASS1"
:global PPOE2-PASS "PASS2"

#Creating default pppoe (optional)
/interface pppoe-client
add disabled=no interface=ether1 name=pppoe-out1 password="$PASS1" user="$USER1"
add disabled=no interface=ether2 name=pppoe-out2 password="$PASS2" user="$USER2"

#Enable dhcp-client in interface 1
/ip dhcp-client
add dhcp-options=hostname,clientid disabled=no interface=ether1
add dhcp-options=hostname,clientid disabled=no interface=ether2

/ip route
add check-gateway=ping comment=Link1 distance=1 gateway=pppoe-out1
add check-gateway=ping comment=Link2 distance=2 gateway=pppoe-out2
add check-gateway=ping comment=Link3 distance=3 gateway=ether1
add check-gateway=ping comment=Link4 distance=4 gateway=ether2
add comment="Static router" distance=1 dst-address=1.0.0.1/32 gateway=pppoe-out1
add comment="Static router" distance=1 dst-address=8.8.4.4/32 gateway=pppoe-out2
add comment="Static router" distance=2 dst-address=1.0.0.1/32 gateway=ether1
add comment="Static router" distance=2 dst-address=8.8.4.4/32 gateway=ether2

/tool netwatch
add down-script="/ip route disable [find comment=\"Link1\"]" host=1.0.0.1 timeout=200ms up-script="/ip route enable [find comment=\"Link1\"]"
add down-script="/ip route disable [find comment=\"Link2\"]" host=8.8.4.4 timeout=200ms up-script="/ip route enable [find comment=\"Link2\"]"

#Creating bridge of the lan
/interface bridge
add comment="bridge lan" name=bridge_lan

#Adding ports to bridge lan (all ports per default)
/interface bridge port
add bridge=bridge_lan interface=ether3
add bridge=bridge_lan interface=ether4
add bridge=bridge_lan interface=ether5

#Creating list of the interfaces
/interface list
add name=wan ; add name=lan

#Adding interfaces to respective list
/interface list member
add interface=bridge_lan list=lan
add interface=ether1 list=wan
add interface=ether2 list=wan
add interface=pppoe-out1 list=wan
add interface=pppoe-out2 list=wan
:delay 5

#Define IP address to bridge lan
/ip address
add address="$IP/24" interface=bridge_lan network="$NETWORK"

#Create of pool to lan
/ip pool
add name=dhcp_lan ranges="$RANGE"

#Enable dhcp-server in bridge lan
/ip dhcp-server
add address-pool=dhcp_lan disabled=no interface=bridge_lan name=dhcp_lan

#Enable dhcp-server in bridge lan
/ip dhcp-server network
add address="$NETWORK/24" gateway="$IP" netmask=24

#Set DNS servers
/ip dns
set servers=1.1.1.1,8.8.8.8,208.67.222.222 allow-remote-requests=yes

#Enable DDNS
/ip cloud
set ddns-enabled=yes ddns-update-interval=5m

#Enable UNPN
/ip upnp
set enable=yes

#Set timezone
/system clock
set date="$DATE" time-zone-autodetect=yes time-zone-name="$TIMEZONE"

#Set hostname
/system identity
set name="$CN"

#Enbale NTP client
/system ntp client
set enabled=yes
/system ntp client servers
add address=200.20.186.76
add address=200.160.0.8

#Enable and set rules of the firewall
/ip firewall filter remove [/ip firewall filter find] ;
:delay 5

/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=wan
/ip firewall filter
#Allow fastrack to related and established traffic
add action=fasttrack-connection chain=forward connection-state=established,related comment="DEFAULT: Fasttrack connections"
#Allow input services
add action=accept chain=input protocol=tcp dst-port=9922 comment="DEFAULT: Accept input connection SSH port"
add action=accept chain=input protocol=icmp src-address=149.56.130.233 comment="DEFAULT: Accept input connection ICMP protocol"
add action=accept chain=input protocol=udp dst-port=161 src-address=149.56.130.233 comment="DEFAULT: Accept input SNMP protocol connection "
#Allow established and related connections
add action=accept chain=forward connection-state=established,related,untracked comment="DEFAULT: Accept established, related, and untracked traffic."
add action=accept chain=input connection-state=established,related,untracked comment="DEFAULT: Accept established, related, and untracked traffic."
#Drop invalids packets
add action=drop chain=forward connection-state=invalid comment="DEFAULT: Drop invalid forward traffic."
add action=drop chain=input connection-state=invalid comment="DEFAULT: Drop invalid input traffic."
#Drop all forwards connections excepts to NAT ports
add action=drop chain=forward connection-nat-state=!dstnat connection-state=new in-interface-list=wan comment="DEFAULT: Drop all forward traffic from WAN that is not DSTNATed."
#Drop all input connections excepts from LAN
add action=drop chain=input in-interface-list=!lan comment="DEFAULT: Drop all input traffic not coming from LAN."
add action=drop chain=input comment="Drop everything else to the router" disabled=yes


#Schedule upgrade and reboot
/system routerboard settings
set auto-upgrade=yes

/system scheduler
add interval=1d name=upgrade_rb on-event=upgrade_rb policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=jun/27/2019 start-time=05:10:00

/system script
add dont-require-permissions=no name=upgrade_rb owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/system package update download\r\
    \n/system routerboard upgrade\r\
    \n/system reboot\r\
    \n"

#Disable loggging for dhcp leases
/system logging
set 0 topics=info,!dhcp

#Enable certificate SSL to Web access
/certificate
add name=local_ca common-name=local_ca key-usage=key-cert-sign,crl-sign days-valid=3650
:execute "/certificate sign local_ca"
:delay 30
add name=Webfig common-name=Webfig days-valid=3650
:execute "/certificate sign Webfig ca=local_ca"
:delay 30

#Disable all services and enable ssh over port 9922
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh address="$NETWORK/24,54.232.35.186/32" port=9922
set www-ssl address="$NETWORK/24" certificate=Webfig disabled=no
set api disabled=yes
set winbox disabled=yes
set api-ssl disabled=yes

#Set password default to RB
/user set admin password="$PWD"

#End Script
