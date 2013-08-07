#!/bin/sh
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
# Purpose
# Main Admin Task for a Oracle NoSQL Store
# Configuration read from nodelist.conf
# For NoSQL Version 2.0  - Oracle 11g R2
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
# read the Store Configuration
. ${SCRIPTS_DIR}/store.conf

#################################################
# define commands used more then one time
STARTCOMMAND="nohup java -jar #KVHOMEI#/lib/kvstore.jar start -root #KVROOTI#  > /tmp/nohup.out &"
STOPCOMMAND="java -jar #KVHOMEI#/lib/kvstore.jar stop -root #KVROOTI#"

#################################################
# create the command file
CREATE_COMMANDFILE="${SCRIPTS_DIR}/create_store_${STORE_NAME[$ADMIN_NODE]}.command"

#Create the creation Script for the store
echo "configure -name ${STORE_NAME[$ADMIN_NODE]}" >  ${CREATE_COMMANDFILE}

# define the Memory Parameter
echo "change-policy -params \"cacheSize=${GLOBAL_CACHE_SIZE_BYTE}\""  >> ${CREATE_COMMANDFILE}
echo "change-policy -params \"javaMiscParams=-server -d64 -XX:+UseCompressedOops -XX:+AlwaysPreTouch -Xms${JAVA_XMS_SIZE_MB}m -Xmx${JAVA_XMX_SIZE_MB}m\" " >> ${CREATE_COMMANDFILE}

echo "plan deploy-datacenter -name \"DC${STORE_NAME[$ADMIN_NODE]}\" -rf $CAPACITY -wait"         >> ${CREATE_COMMANDFILE}

ELEMENT_COUNT=${#STORE_NODE[@]}
INDEX=0
while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
	do    # List all the elements in the array.
	echo "plan deploy-sn -dc dc1 -host ${STORE_NODE[$INDEX]} -port ${STORE_PORT[$INDEX]} -wait" >> ${CREATE_COMMANDFILE}
	let "SNNODE = $INDEX + 1"
	echo "plan deploy-admin -sn sn${SNNODE} -port ${ADMIN_PORT} -wait"                          >> ${CREATE_COMMANDFILE}
	let "INDEX = $INDEX + 1"
done
echo "pool create -name ${STORE_NAME[$ADMIN_NODE]}Pool"                                         >>  ${CREATE_COMMANDFILE}

INDEX=0
while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
	do    # List all the elements in the array.
	let "SNNODE = $INDEX + 1"
	echo "pool join   -name ${STORE_NAME[$ADMIN_NODE]}Pool -sn sn${SNNODE}"                                      >>  ${CREATE_COMMANDFILE}
	echo "plan change-parameters -service sn${SNNODE} -wait -params mgmtClass=oracle.kv.impl.mgmt.jmx.JmxAgent"  >>  ${CREATE_COMMANDFILE}
	let "INDEX = $INDEX + 1"
done
echo "topology create -name topo -pool ${STORE_NAME[$ADMIN_NODE]}Pool -partitions 500" >>  ${CREATE_COMMANDFILE}
echo "plan deploy-topology -name topo -wait"                                           >>  ${CREATE_COMMANDFILE}

printLine "Show the configuration file ${CREATE_COMMANDFILE}"
printLine 
cat ${CREATE_COMMANDFILE}
printLine 
printLine "Show the configuration Parameter of the Store ${STORE_NAME[$ADMIN_NODE]}"

printList "Parameter STORE_NAME"      30 "::"  "${STORE_NAME[$ADMIN_NODE]}"
printList "Parameter HTTP_ADMIN_PORT" 30 "::"  "$HTTP_ADMIN_PORT"
printList "Parameter HA_RANGE"        30 "::"  "$HA_RANGE"
printList "Parameter SERVICERANGE"    30 "::"  "$SERVICERANGE"
printList "Parameter ADMIN_PORT"      30 "::"  "$ADMIN_PORT"
printList "Parameter CAPACITY"        30 "::"  "$CAPACITY"
printList "Parameter NUM_CPU"         30 "::"  "$NUM_CPU"
printList "Parameter MEMORY_MB"       30 "::"  "$MEMORY_MB"


#
askYesNo "Do you really like to create the store now?" "NO"
if [ "${YES_NO_ANSWER}" = 'YES' ]; then
 printLine  ""
else
 printError
 printError "Stop Configuraton and exit"
 printError
 exit 1
fi
	
# Verzeichnisse auf den Knoten anlegen
printError
COMMAND_TITLE="Creation of the store directory"
COMMAND="mkdir -p #KVROOTI#"
COMMANDUSR=`whoami`
doStore
printError
# Check for enviroment
printLine "Last check  of the Enviroment"
doCheck
printError

# Boot Config crate
printError
printLine "Create the boot config XML for each node"
printLine "--"

COMMAND_TITLE=""
COMMAND="java -jar #KVHOMEI#/lib/kvstore.jar makebootconfig -root #KVROOTI# -port #KVPORT# -admin #ADMINPORT# -host #KVHOSTNAME# -harange #HARANGE# -capacity #CAPACITY# -num_cpus #NUMCPU# -memory_mb #MEMORY# -servicerange #SERVICERANGE#"

INDEX=0
while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
	do    # List all the elements in the array.
	echo -- Creation Store Config for NoSQL Store ${STORE_NAME[$INDEX]} on ${STORE_NODE[$INDEX]}  at "`date`"
		
	KVROOTI=${STORE_ROOT[$INDEX]}
	KVHOMEI=${STORE_HOME[$INDEX]}			
		
	COMMANDI=${COMMAND//#KVROOTI#/${KVROOTI}}
	COMMANDI=${COMMANDI//#KVHOMEI#/${KVHOMEI}}
	COMMANDI=${COMMANDI//#KVPORT#/${STORE_PORT[$INDEX]}}
	COMMANDI=${COMMANDI//#ADMINPORT#/${HTTP_ADMIN_PORT}}
	COMMANDI=${COMMANDI//#KVHOSTNAME#/${STORE_NODE[$INDEX]}}
	COMMANDI=${COMMANDI//#HARANGE#/${HA_RANGE}}
	COMMANDI=${COMMANDI//#CAPACITY#/${CAPACITY}}
	COMMANDI=${COMMANDI//#NUMCPU#/${NUM_CPU}}
	COMMANDI=${COMMANDI//#MEMORY#/${MEMORY_MB}}
	COMMANDI=${COMMANDI//#SERVICERANGE#/${SERVICERANGE}}
		
	echo -- use Command:: ${COMMANDI}
	ssh  ${STORE_NODE[$INDEX]} "${COMMANDI}"
	let "INDEX = $INDEX + 1"
done
printError

#start Nodes
printLine
printLine "Start the nodes"
. ${SCRIPTS_DIR}/noSQLStore.sh start
printLine

# Wait until every Thing is fine
printLine
waitStart 15
printLine

#check 
printLine
. ${SCRIPTS_DIR}/noSQLStore.sh status
printLine

# start the admin
# and configure the enviroment
#
printLine
printLine "Start the configuration"
java -jar ${STORE_HOME[$ADMIN_NODE]}/lib/kvstore.jar runadmin -port ${STORE_PORT[$ADMIN_NODE]} -host ${STORE_NODE[$ADMIN_NODE]} < ${CREATE_COMMANDFILE}
printf  "%s\n" ""
printLine
#
#
printError
waitStart 10
. ${SCRIPTS_DIR}/noSQLStore.sh ping
printError


