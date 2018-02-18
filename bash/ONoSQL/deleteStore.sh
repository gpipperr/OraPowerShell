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
STOPCOMMAND="java -jar #KVHOMEI#/lib/kvstore.jar stop -root #KVROOTI#"

#################################################
# create the command file
CREATE_COMMANDFILE="${SCRIPTS_DIR}/create_store_${STORE_NAME[$ADMIN_NODE]}.command"

#
askYesNo "Do you really like to delete the store  ${STORE_NAME[$ADMIN_NODE]} now?" "NO"
if [ "${YES_NO_ANSWER}" = 'YES' ]; then
 printLine  ""
else
 printError
 printError "Stop Configuraton and exit"
 printError
 exit 1
fi
	
# Store stoppen
printError
. ${SCRIPTS_DIR}/noSQLStore.sh stop
printError
# Wait until every Thing is fine
printError
waitStart 5
printError

# stop all Java
printError
. ${SCRIPTS_DIR}/noSQLStore.sh kill
printError
# show status
printError
. ${SCRIPTS_DIR}/noSQLStore.sh status
printError

# remove the disks
printError
COMMAND_TITLE="Creation store directory"
COMMAND="rm -rf #KVROOTI# #KVROOTI#.old"
COMMANDUSR=`whoami`
doStore
printError
printError "Store removed"
printError







