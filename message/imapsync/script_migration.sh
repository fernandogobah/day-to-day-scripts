#!/bin/bash
# Author: Fernando Lima
# E-mail: fernandogobah@gmail.com
# Last Update: 2022-04-07
# Desc: Script to migrate mail accounts among servers

cat /opt/imapsync/email_migrate.txt|grep -v "^#" | sed '/^ *$/d' > /tmp/list-full
LIST="/tmp/list-full"
HOST_ORIGIN="imap.olddomain.com"
HOST_DESTINY="mail.newdomain.com"

while IFS=: read user_origin pass_origin user_destiny pass_destiny;do

echo -e "\n\nsync account ${user_origin}...\n\n"
imapsync --host1 ${HOST_ORIGIN} --ssl1 --port1 993 --user_origin "${user_origin}" --password1 "${pass_origin}" --host2 ${HOST_DESTINY} --user2 "${user_destiny}" --password2 "${pass_destiny}"

done < ${LIST}
