# !/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to export accounts data

TMP=/tmp/export_data
if [ ! -d /tmp/export_data ]
	then
		mkdir /tmp/export_data
	else
		for MAIL in $(zmprov -l gaa | sort); 	do
		zmmailbox -z -m $MAIL getRestURL "/Tasks?fmt=ics" > $TMP/"$MAIL".tasks
		zmmailbox -z -m $MAIL getRestURL "/Calendar?fmt=ics" > $TMP/"$MAIL".calendar
		zmmailbox -z -m $MAIL getRestURL "/Contacts?fmt=csv" > $TMP/"$MAIL".contacts
		zmmailbox -z -m $MAIL getRestURL "/Emailed Contacts?fmt=csv" > $TMP/"$MAIL".collected
		done
	fi
