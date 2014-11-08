#!/bin/sh
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
# Purpose
# Main Admin Task for a Oracle NoSQL Store
# Configuration read from nodelist.conf
#
# For NoSQL Version 2.1  - Oracle 12c R1
#
# 
########## Enviroment ##############

SCRIPTPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
SCRIPTS_DIR=`dirname "$SCRIPTPATH{}"`

# for Log usage
DAY_OF_WEEK="`date +%w`"
export DAY_OF_WEEK 
DAY="`date +%d`"
export DAY

. ${SCRIPTS_DIR}/bash_lib.sh

#################################################
# read the Node Configuration
declare -a STORE_NODE
declare -a STORE_ROOT
declare -a STORE_HOME
declare -a STORE_NAME

. ${SCRIPTS_DIR}/nodelist.conf


#################################################
# define commands used more then one time
STARTCOMMAND="nohup java -jar #KVHOMEI#/lib/kvstore.jar start -root #KVROOTI#  > /tmp/nohup.out &"
STOPCOMMAND="java -jar #KVHOMEI#/lib/kvstore.jar stop -root #KVROOTI#"


#################################################
# Check command parameter 
case "$1" in
    start)
        # start all Storage Nodes
        COMMAND_TITLE="Starting Store"
		COMMAND=${STARTCOMMAND}
		COMMANDUSR=`whoami`
		doStore
        printLine "OK"
        ;;
    stop)
        # stop all Storage Nodes
        COMMAND_TITLE="Shutdown Store"
		COMMAND=${STOPCOMMAND}
		COMMANDUSR=`whoami`
        doStore
        printLine "OK"
        ;;
	 admin)
        # admin
		printLine "-- Command java -jar $KVHOME/lib/kvstore.jar runadmin -port 5000 -host $HOSTNAME"  
        java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar runadmin -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]}
        ;;	
	 console)
        # kvshell
		printLine "-- Command java -jar $KVHOME/lib/kvcli.jar -host $HOSTNAME -port ${STORE_PORT[$ADMIN_NODE]} -store ${STORE_NAME[$ADMIN_NODE]}"
        java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvcli.jar -host $HOSTNAME -port ${STORE_PORT[$ADMIN_NODE]} -store ${STORE_NAME[$ADMIN_NODE]}
        ;;	
     count)
        # kvshell
		printLine "-- Command java -jar $KVHOME/lib/kvcli.jar -host $HOSTNAME -port ${STORE_PORT[$ADMIN_NODE]} -store ${STORE_NAME[$ADMIN_NODE]} aggregate -count"
        java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvcli.jar -host $HOSTNAME -port ${STORE_PORT[$ADMIN_NODE]} -store ${STORE_NAME[$ADMIN_NODE]} aggregate kv -count
        ;;			
	 ping)
        # ping
		printLine "-- Command java -jar $KVHOME/lib/kvstore.jar ping -port 5000 -host $HOSTNAME" 
        java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar ping -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]}    
        ;;	
    status)
        # status of the nodes 
        COMMAND_TITLE="Check Status "
		COMMAND="jps -m | grep kv"
		COMMANDUSR=`whoami`
        doStore
        ;;
	kill)
        # status
        COMMAND_TITLE="Kill all "
		COMMAND="killall java"
		COMMANDUSR=`whoami`
        doStore
        ;;	
	fwstatus)
        # status
        COMMAND_TITLE="Check the firewall Rules "
		COMMAND="iptables -L -n"
		COMMANDUSR="root"
        doStore
        ;;	
	cleanLogfile)
		# save copy of all logfiles
		COMMAND_TITLE="clean Logfiles: "
		COMMAND="find #KVROOTI#/. -name \"*.log\" -exec mv {} {}.old_${DAY_OF_WEEK} \;"
		COMMANDUSR=`whoami`
		doStore
		# remove all logfiles
		COMMAND="find #KVROOTI#/. -name \"*.log\" -exec rm {} \;"
		doStore
		;;	
	getStoreSize)
		# get the store total size on disk
		COMMAND_TITLE="Get Store total Size on disk for each node: "
		COMMAND="du -sh  #KVROOTI#"
		COMMANDUSR=`whoami`
		doStore		
		;;		
	getStoreSizeDetail)
		# get the store total size on disk
		COMMAND_TITLE="Get Store total Size on disk for each node: "
		COMMAND="du -h  #KVROOTI#"
		COMMANDUSR=`whoami`
		doStore		
		;;		
	catLogfile)
		# remove all logfiles
		COMMAND_TITLE="clean Logfiles: "
		COMMAND="find #KVROOTI#/. -name \"*.log\" -exec sh -c \"echo cut >  {}\"  \;"
		COMMANDUSR=`whoami`
		doStore		
		;;	
	readLogfile)
		# remove all logfiles
		COMMAND_TITLE="read Logfiles: "
		COMMAND="grep Exception #KVROOTI#/*.log"
		COMMANDUSR=`whoami`
		doStore
		COMMAND="grep Exception #KVROOTI#/#STORENAME#/log/*.log"
		doStore
		;;	
    reload|restart)
        # stop and restart 
        COMMAND_TITLE="Starting Store:"
		COMMAND=${STARTCOMMAND}
		COMMANDUSR=`whoami`
		doStore
        COMMAND_TITLE="Shutdown Store: "
		COMMAND=${STOPCOMAND}
		COMMANDUSR=`whoami`
        doStore
        printLine "OK"
        ;;
	createStore)
        # createStore
        echo "       createStore  -> Use the Script createStore.sh  "
        ;;	
    *)
      echo "-- Check the configuration file entries in nodelist.conf"
	  doCheck
	  echo " "
	  echo "Usage: $0 <parameter"
	  echo "       start        -> Start on each node the SN   "
	  echo "       stop         -> Stop on each Node the SN    "
	  echo "       restart      -> Restart on each Node the SN "
	  echo "       reload       -> Restart on each Node the SN "
	  echo "       status       -> Status on each node the SN  "
	  echo "       kill         -> Kill on each node the SN with killall java "
	  echo "       admin        -> Start the admin console     "
	  echo "       console      -> Start the kvshell console   "
	  echo "       count        -> Count all entries in the store  "
	  echo "       ping         -> Ping the Store               "
	  echo "       getStoreSize -> get the Disk size for the store for each node"
	  echo "       getStoreSizeDetail -> get he Disk size for the store for each node for each SN"
	  echo "       fwstatus     -> Show the status of the FW as root!  "
	  echo "       cleanLogfile -> Clean Log file on each node the SN  "
	  echo "       readLogfile  -> Search Error in the logfile on each node the SN  "
	  echo "       catLogfile   -> Cut the logfile on each node the SN  "
	  echo "       createStore  -> Use the Script createStore.sh        "
	  echo "       celeteStore  -> Use the Script deleteStore.sh        "
	  exit 1	  
	  
esac


 
#################################################
# finish