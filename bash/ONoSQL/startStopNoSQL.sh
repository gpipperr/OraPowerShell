#!/bin/bash
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
# Run-level Startup script NoSQL
#
# chkconfig: 2345 08 92
# description:  Starts, stops NoSQL
#
#
### BEGIN INIT INFO
# Provides: OracleNoSQLKVStore
# Required-Start: 92
# Required-Stop:  08
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: start and stop OracleNoSQLKVStore
# Description: Start, stop and save OracleNoSQLKVStore
### END INIT INFO


# Source function library.
. /etc/init.d/functions

ORACLE_USER=oracle
KVHOME=/opt/oracle/produkt/11.2.0/kv-2.0.39
KVROOT=/opt/oracle/kvdata/

#Start or stop the Oracle NoSQL Node
case "$1" in
    start)
        # Oracle NoSQL start
        echo -n "Starting Oracle: "
        su - $ORACLE_USER -c "nohup java -jar $KVHOME/lib/kvstore.jar start -root $KVROOT > /tmp/nohup.out 2>&1 &"
        echo "OK"
        ;;
    stop)
        # Oracle Nosql shutdown
        echo -n "Shutdown Oracle: "
        su - $ORACLE_USER -c "java -jar $KVHOME/lib/kvstore.jar stop -root $KVROOT"
        echo "OK"
        ;;
    status)
        # status
        echo -n "Status Oracle: "
        jps -m | grep kv
        ;;	    
    reload|restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "Usage: $0 start|stop|restart|reload|status"
        exit 1
esac
exit 0