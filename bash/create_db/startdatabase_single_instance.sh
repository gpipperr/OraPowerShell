#!/bin/bash
#
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
# Run-level Startup script Oracle Instance und Listener
#
# Edit the /etc/oratab file to verify that the entry for your database is correct.
# A Y indicates that the database should be started automatically on server reboot, and an N indicates that it should not.
# Set the permissions on the dbora file to 744:
#
# $ chmod 744 /etc/init.d/dbora#
#
# After creating the dbora file, you need to link it to /etc/rc3.d and /etc/rc0.d for startup and shutdown.
# You may use the chkconfig command to create the links as follows:
#
#  $ cd /etc/init.d
#  $ /sbin/chkconfig --add dbora
# chkconfig: 35 99 10
# description: Start and stop the Oracle database, listener and DB Control
#
#use the GPI default oracle home script
. /home/oracle/.profile 
setdb 2
#or
#ORACLE_HOME="/u01/app/oracle/product/11.2.0/dbhome_1"

ORACLE_USER="oracle"

#dbstart existiert?
 
if [ ! -f $ORACLE_HOME/bin/dbstart -o ! -d $ORACLE_HOME ]
then
        echo "Oracle startup: cannot start"
        exit 1
fi
 
# Datenbank starten oder stoppen
 
case "$1" in
    start)
        # Oracle listener and instance startup
        echo -n "Starting Oracle: "
        su - $ORACLE_USER -c "$ORACLE_HOME/bin/lsnrctl start"
        su - $ORACLE_USER -c $ORACLE_HOME/bin/dbstart $ORACLE_HOME
        su - $ORACLE_USER -c "export ORACLE_SID=GPIDB; $ORACLE_HOME/bin/emctl start dbconsole"
        touch /var/lock/subsys/oracle
        echo "OK"
        ;;
    stop)
        # Oracle listener and instance shutdown
        echo -n "Shutdown Oracle: "
        su - $ORACLE_USER -c "export ORACLE_SID=GPIDB; $ORACLE_HOME/bin/emctl stop dbconsole"
        su - $ORACLE_USER -c "$ORACLE_HOME/bin/lsnrctl stop"
        su - $ORACLE_USER -c $ORACLE_HOME/bin/dbshut $ORACLE_HOME
        rm -f /var/lock/subsys/oracle
        echo "OK"
        ;;
	status) # Get Status of the Oracle databases and listeners
		su - $ORACLE_USER -c "$ORACLE_HOME/bin/srvctl status database -d GPIDB"
		su - $ORACLE_USER -c "export $ORACLE_HOME/bin/emctl status dbconsole"
	;;
    reload|restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "Usage: $0 start|stop|restart|reload"
        exit 1
esac
exit 0

