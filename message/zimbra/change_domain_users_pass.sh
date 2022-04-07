#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to change all Zimbra user password accounts at once, to one specific domain.

dominio=domain.tld

zmprov -l gaa $dominio >> users.txt
for i in $(cat users.txt); do zmprov sp $i newpass; done

for each in "zmprov -l gaa '$dominio'"; do zmprov ma $each zimbraPasswordMustChange TRUE; done
