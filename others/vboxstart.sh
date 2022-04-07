#!/bin/bash
 
iniciar()
{
su user -c	"/usr/bin/VBoxHeadless -startvm srvhtpc -vrde on -e "TCP/Ports=3500" &"
}
 
parar()
{
su user -c	"/usr/bin/VBoxManage controlvm srvhtpc poweroff"
}
 
case "$1" in
	start)
		iniciar;;
	stop)
		parar;;
	*)
		echo "Formato: /etc/init.d/vboxstart.sh {start|stop}"
		exit 1
esac
exit 0
