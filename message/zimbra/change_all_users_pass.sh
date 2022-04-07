#!/bin/bash
# Author: Marcos Azevedo
# E-mail: psylinux@gmail.com
# Last Update: 2019-02-02
# Desc: Script to change all Zimbra user password accounts at once.

USERS=`su - zimbra -c 'zmprov -l gaa'`;

# Clearing the screen
clear

# Checking for script parameters
if [ $# -gt 0 ]; then
	NEWPASS=$1
else
	echo -e "[+] Please specify the new password..."
	echo -e "Usage: $0 Your_New_Password"
	exit 1
fi

echo -e "[+] Changing all Zimbra users password"
for ACCOUNT in $USERS; do
	ACC1=`echo $ACCOUNT | awk -F@ '{print $1}'`;
	ACC=`echo $ACC1 | cut -d '.' -f1`;
	if [ $ACC == "admin" ] || [ $ACC == "wiki" ] || [ $ACC == "galsync" ] || [ $ACC == "ham" ] || [ $ACC == "spam" ] || [ $ACC == "virus-quarantine" ]; then
		echo "Skipping system account: $ACC";
	else
		echo -e "[+] Modifying $ACCOUNT password";
		su - zimbra -c "zmprov sp $ACCOUNT $NEWPASS";
		su - zimbra -c "zmprov ma $ACCOUNT zimbraPasswordMustChange TRUE";
		echo -e "[+] Done!"
		echo -e "----------"
	# read anykey
	fi
done
echo -e "[+] Modifying password for all user has been finished successfully"


