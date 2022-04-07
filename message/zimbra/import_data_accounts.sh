# !/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to import accounts data

TMP=/tmp/export_data

for ACC in $(ls $TMP | grep _tasks.ics) ; do
	MAIL=$(echo $ACC | awk -F "_tasks.ics" '{print $1}')
	zmmailbox -z -m $MAIL postRestURL "/Tasks?fmt=ics" $TMP/$ACC
done

for ACC in $(ls $TMP | grep _calendar.ics) ; do
	MAIL=$(echo $ACC | awk -F "_calendar.ics" '{print $1}')
	zmmailbox -z -m $MAIL postRestURL "/Calendar?fmt=ics" $TMP/$ACC
done

for ACC in $(ls $TMP | grep _contacts.csv) ; do
	MAIL=$(echo $ACC | awk -F "_contacts.csv" '{print $1}')
	zmmailbox -z -m $MAIL postRestURL "/Contacts?fmt=csv" $TMP/$ACC
done

for ACC in $(ls $TMP | grep _contacts_collected.csv) ; do
	MAIL=$(echo $ACC | awk -F "_contacts_collected.csv" '{print $1}')
	zmmailbox -z -m $MAIL postRestURL "/Emailed Contacts?fmt=csv" $TMP/$ACC
done

