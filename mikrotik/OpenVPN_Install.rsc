#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to configure Mikrotik with VPN (OpenVPN)

#Variables
:global CN "BUSINESS_NAME"
:global COUNTRY "BR"
:global STATE "GO"
:global LOC "CITY_NAME"
:global OU ""
:global KEYSIZE "2048"
:global PORT "32400"
:global USERNAME "VPN-USER"
:global PASSWORD "VPN-PASS"

## generate a CA certificate
/certificate
add name=ca-template country="$COUNTRY" state="$STATE" locality="$LOC" \
  organization="$CN" unit="$OU" common-name="$CN" key-size="$KEYSIZE" \
  days-valid=3650 key-usage=crl-sign,key-cert-sign
:execute "/certificate sign ca-template ca-crl-host=127.0.0.1 name=\"$CN\""
:delay 30

## generate a server certificate
/certificate
add name=server-template country="$COUNTRY" state="$STATE" locality="$LOC" \
  organization="$CN" unit="$OU" common-name="server@$CN" key-size="$KEYSIZE" \
  days-valid=3650 key-usage=digital-signature,key-encipherment,tls-server
:execute "/certificate sign server-template ca=\"$CN\" name=\"server@$CN\""
:delay 30

## create a client template
/certificate
add name=client-template country="$COUNTRY" state="$STATE" locality="$LOC" \
  organization="$CN" unit="$OU" common-name="client" \
  key-size="$KEYSIZE" days-valid=3650 key-usage=tls-client

## create IP pool
/ip pool
add name=VPN-POOL ranges=192.168.252.128-192.168.252.224

## add VPN profile
/ppp profile
add dns-server=192.168.252.1 local-address=192.168.252.1 name=VPN-PROFILE \
  remote-address=VPN-POOL use-encryption=yes

## setup OpenVPN server
/interface ovpn-server server
set auth=sha1 certificate="server@$CN" cipher=aes128,aes192,aes256 \
  default-profile=VPN-PROFILE enabled=yes mode=ip netmask=24 port=32400 \
  require-client-certificate=yes

## add a firewall rule
/ip firewall filter
add chain=input action=accept dst-port="$PORT" protocol=tcp \
  comment="Allow OpenVPN"
add chain=input action=accept dst-port=53 protocol=udp \
  src-address=192.168.252.0/24 \
  comment="Accept DNS requests from VPN clients"
move [find comment="Allow OpenVPN"] 0
move [find comment="Accept DNS requests from VPN clients"] 1
add chain=forward action=accept src-address=192.168.252.0/24 \
  out-interface-list=wan place-before=0
add chain=forward action=accept in-interface-list=wan \
  dst-address=192.168.252.0/24 place-before=1
/ip firewall nat
add chain=srcnat src-address=192.168.252.0/24 out-interface-list=wan \
  action=masquerade

## add user
/ppp secret
add name=$USERNAME password=$PASSWORD profile=VPN-PROFILE service=ovpn

## generate client certificate
/certificate
add name=client-template-to-issue copy-from="client-template" \
  common-name="$USERNAME@$CN"
:execute "/certificate sign client-template-to-issue ca=\"$CN\" name=\"$USERNAME@$CN\""
:delay 30

## export the CA, client certificate and private key
/certificate
export-certificate "$CN" export-passphrase=""
export-certificate "$USERNAME@$CN" export-passphrase="$PASSWORD"
/
