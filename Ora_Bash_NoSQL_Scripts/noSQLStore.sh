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
# For NoSQL Version 3.1  - Oracle 12c R3
#
# 
########## Environment ##############

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

################################################
# check Security Configuration
if [ "${ADMIN_SEC_CONFIG}" == "TRUE" ];
then
	STORE_CONNECT_SECURITY="-security ${STORE_ROOT[$ADMIN_NODE]}/security/${ADMIN_SECRET}"
else
    STORE_CONNECT_SECURITY=""
fi


############################################

createUser() {
	printf "Name of the Store User:"
	read USER_NAME
	printf "Password of the Store User:"
	read USER_PWD

	# create the command file for the store user
	CREATE_USER_COMMANDFILE="${SCRIPTS_DIR}/create_storeuser_${USER_NAME}_${STORE_NAME[$ADMIN_NODE]}.command"

	# create the Store user
	echo "plan create-user -name ${USER_NAME} -password ${USER_PWD} -wait"    >${CREATE_USER_COMMANDFILE}
	echo "plan grant -role readwrite -user ${USER_NAME} -wait"               >>${CREATE_USER_COMMANDFILE}
	echo "show user -name ${USER_NAME}"                                      >>${CREATE_USER_COMMANDFILE}

	java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar runadmin -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY} < ${CREATE_USER_COMMANDFILE}

	java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar securityconfig pwdfile  create  -file ${STORE_ROOT[0]}/security/${USER_NAME}.pwd
	java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar securityconfig pwdfile  secret  -file ${STORE_ROOT[0]}/security/${USER_NAME}.pwd -set -alias ${USER_NAME} -secret ${USER_PWD}

	#Root user configuration anlegen
	echo "oracle.kv.ssl.trustStore=client.trust"               > ${STORE_ROOT[0]}/security/${USER_NAME}_user.security 
	echo "oracle.kv.transport=ssl"                            >> ${STORE_ROOT[0]}/security/${USER_NAME}_user.security 
	echo "oracle.kv.ssl.protocols=TLSv1.2,TLSv1.1,TLSv1"      >> ${STORE_ROOT[0]}/security/${USER_NAME}_user.security 
	echo "oracle.kv.ssl.hostnameVerifier=dnmatch(CN\=NoSQL)"  >> ${STORE_ROOT[0]}/security/${USER_NAME}_user.security 
	echo "oracle.kv.auth.pwdfile.file=${USER_NAME}.pwd"       >> ${STORE_ROOT[0]}/security/${USER_NAME}_user.security 
	echo "oracle.kv.auth.username=${USER_NAME}"               >> ${STORE_ROOT[0]}/security/${USER_NAME}_user.security 

	echo "-- Copy the Login Information to the other Nodes"
	ELEMENT_COUNT=${#STORE_NODE[@]}
	INDEX=1
	while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
		do 
		scp ${STORE_ROOT[0]}/security/${USER_NAME}_user.security   ${STORE_NODE[$INDEX]}:${STORE_ROOT[$INDEX]}/security/${USER_NAME}_user.security
		scp ${STORE_ROOT[0]}/security/${USER_NAME}.pwd             ${STORE_NODE[$INDEX]}:${STORE_ROOT[$INDEX]}/security/${USER_NAME}.pwd
		let "INDEX = $INDEX + 1"
	done

	printError
}

dropUser(){
	printf "Name of the Store User:"
	read USER_NAME
	# create the command file for the store user
	CREATE_USER_COMMANDFILE="${SCRIPTS_DIR}/create_storeuser_${USER_NAME}_${STORE_NAME[$ADMIN_NODE]}.command"

	# create the Store user
	echo "show user -name ${USER_NAME}"                 >${CREATE_USER_COMMANDFILE}
	echo "plan drop-user -name ${USER_NAME} -wait"     >>${CREATE_USER_COMMANDFILE}

	java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar runadmin -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY} < ${CREATE_USER_COMMANDFILE}

	echo "-- Delete the login Information from all nodes"
	COMMAND_TITLE="remove Login Information"
	COMMAND="rm #KVROOTI#/security/${USER_NAME}*"
	COMMANDUSR=`whoami`
	doStore
	printLine "OK"
	printError
}

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
		printLine "-- Command java -jar $KVHOME/lib/kvstore.jar runadmin -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY} "  
        java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar runadmin -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY}
        ;;	
	 console)
        # kvshell
		printLine "-- Command java -jar $KVHOME/lib/kvcli.jar -host $HOSTNAME -port ${STORE_PORT[$ADMIN_NODE]} -store ${STORE_NAME[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY}"
		printLine "-- To connect to the store connect with \"connect store -name ${STORE_NAME[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY}\""
        java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvcli.jar -host $HOSTNAME -port ${STORE_PORT[$ADMIN_NODE]} -store ${STORE_NAME[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY}
        ;;	
     count)
        # kvshell
		printLine "-- Command java -jar $KVHOME/lib/kvcli.jar -host $HOSTNAME -port ${STORE_PORT[$ADMIN_NODE]} -store ${STORE_NAME[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY} aggregate kv -count"
        java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvcli.jar -host $HOSTNAME -port ${STORE_PORT[$ADMIN_NODE]} -store ${STORE_NAME[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY} aggregate kv -count
        ;;			
	 ping)
        # ping
		printLine "-- Command java -jar $KVHOME/lib/kvstore.jar ping -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY}" 
        java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar ping -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]} ${STORE_CONNECT_SECURITY}   
        ;;
	createUser)
		#create a store user
		createUser
		;;
	dropUser)
		#drop a store user
		dropUser
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
	  echo "       createUser   -> Create a user in the store   "
	  echo "       dropUser     -> Create a user in the store   "
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