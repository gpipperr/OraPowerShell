################# Database deinstallation script ##########################
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
#####################################################################
# Database deinstaller for a Database
#
####################################################################

## environment ######################################################

# Home of the scripts
SCRIPTPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
SCRIPTS=`dirname "$SCRIPTPATH{}"`
export SCRIPTS

##  read default config 
CONFFILE=${SCRIPTS}/default.conf
. ${CONFFILE}

############ source the helper functions ###########################

. installdb_helper.sh

###################################################################

# read default db configuration file 
. ~/.profile


###################################################################
printLine
printLine  "Welcome to the destroy/de installation of the Database"
printLine

# check primary configuration
printLine "Check enviroment ....."
checkEnv
printLine "............... finish"

################### GPIDB #####################################################



PWDFILE=${SCRIPTS}/password.conf
export PWDFILE

## Read encrypted password conf it exits in to memory #########################

if [ -f "${PWDFILE}.des3" ]; then
	dencryptPWDFile
	. ${PWDFILE}
	rm ${PWDFILE}
else
  if [ -f "${PWDFILE}" ]; then
		. ${PWDFILE}
		rm ${PWDFILE}
	else
	 printLine "no preconfiguration password.conf found"
	fi
fi
printLine "SYS User Password of the database"

askPassword "NOCHECK" "SYS" "${S_SYS_USER_PWD}" ""
SYS_USER_PWD=${USER_PWD_ANSWER}

printLine

###############################################################################

###############################################################################

printLine  "Check on installed ASM enviroment"

###################################################################
if [ "${ASM_ENV}" = "true" ]; then
	printLine  "ASM Enviroment dedected - DB will be removed from ASM"
	setdb 1 
	printLine  "Please enter the password of the SYS user of the ASM instance"
	askPassword "ASMCHECK" "SYS" "${S_SYSASM_USER_PWD}" "" "for ASM"
	SYSASM_USER_PWD=${USER_PWD_ANSWER}
	printLine
fi

printf "  please enter the Name of the database you like to remove [%s]: " "${S_DATABASE_NAME}"
read ORACLE_DBNAME

printf "  Please select the enviroment of the DB ${ORACLE_DBNAME}"
printf "  if the enviroment not exists set the .profile_conf with setdbConfigure!"
setdb

if [ ! -n "${ORACLE_DBNAME}" ]; then
	ORACLE_DBNAME=${S_DATABASE_NAME}
fi

ORACLE_SID=${ORACLE_DBNAME}

if [ "${RAC_ENV}" = "true" ]; then
	ORACLE_SID="${ORACLE_DBNAME}1"
fi

export ORACLE_SID

###################################################################
printLine	
printLine   "Environment"
printList  "Database" "20"  ":" 	"${ORACLE_DBNAME}"

if [ ${RAC_ENV} = 'true' ]; then
  for NODE in $VIPNODES
  do
		printList "Hostnames" "20"  ":" 	"${NODE}"		
	done
else
	 printList   "Hostname" "20"  ":" 	"${DBHOST_NAME}"
fi


if [ "${ASM_ENV}" = "true" ]; then
  if [ "${RAC_ENV}" = "true" ]; then
	  printList   "Scanlistner" "20"  ":" 	"${SCAN_LISTNER}" 
		printList   "DB Version" "20"  ":" 	"RAC - Real Application Cluster"
	else
	 printList   "DB Version" "20"  ":" 	"Single Instance"
	fi	
	printList   "DB Version" "20"  ":" 	"ASM Storage"
	
else
	printList   "DB Version" "20"  ":" 	"Single Instance"
	printList   "DB Version" "20"  ":" 	"Filesystem Storage"
fi

printList   "DB Version" "20"  ":" 	"${DB_VERSION}"
printList   "DB Edition" "20"  ":" 	"${DB_EDITON}"



###################################################################

printError
printError	 "IF you really like to kill this database ${ORACLE_DBNAME} please typ in YES!"
printError
askYesNo  "Kill the database ${ORACLE_DBNAME} with the SID: ${ORACLE_SID}" "NO"

printError
if [ "${YES_NO_ANSWER}" = 'YES' ]; then
 printLine  "Start killing ........... "
else
 printError
 printError "You cancel the delete of the DB with the answer ${YES_NO_ANSWER}"
 printError
 exit 1
fi

printLine "Check for ASM"
# ignore case for testing
ORACLE_DBNAME_TEST=`echo ${ORACLE_SID} | tr '[A-Z]' '[a-z]'`
# if ASM  exits with not possilbe
if [ "${ORACLE_DBNAME_TEST:0:4}" = "+asm" ]; then
		echo "You have chossen the wrong database ASM can not contain schemas - Your SID :: ${ORACLE_SID} - Please choose the right DB!" 
		exit 1
else
 printLineSuccess "Sucess!"
fi	

printLine "try to connect to database with the SID:" "${ORACLE_SID}"

# check that the DB is not running anymore
printLine "Check for running DB process for ora_smon_${ORACLE_SID}"
DB_SMON_PROCESS_ID=`ps -Af | grep ora_smon_${ORACLE_SID} | grep -v grep| wc -l`

if [ "${DB_SMON_PROCESS_ID}" = "1" ]; then

	printLine "DB for the ora_smon_${ORACLE_SID} exists -- connect with the SID: ${ORACLE_SID} and the Oracle Home : ${ORACLE_HOME}"

export ORACLE_SID=${ORACLE_SID}

TEST_CONNECT=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
	set heading  off
	set pagesize 0
	set feedback off	
	select 'Sucess! DB Connection to database '||global_name||' established' from global_name;
	exit;
EOScipt`

	if [ "$?" -ne "0" ]; then 
				echo "Can not connect to the Oracle database with the given SID ${ORACLE_SID} - Fix the DB connection first" 
			 CAN_CONNECT=false		
	else
		 printLineSuccess ${TEST_CONNECT}
	fi

	if [ "${CAN_CONNECT}" = 'false' ]; then 
	 printError "DB is not running - do you like try a clean db files?"
	 askYesNo  "Clean the ${ORACLE_DBNAME} files from the storage?" "NO"
		if [ "${YES_NO_ANSWER}" = 'YES' ]; then
		 printLine  "Start killing  next steps ............. "
		else
		 printError
		 printError "You cancel the delete of the DB with the answer ${YES_NO_ANSWER}"
		 printError
		 exit 1
		fi 
	fi
else
 printError "DB is not running - try to start as next step "
 CAN_CONNECT=false		
fi

###################################################################

#FIX
# GET List of all datafiles to delete
# GET List of all redolog files to delete
# GET List of all controlfiles to delete

#################################################################

# stop em console 
# FIx check for OEM Home like  
if [ -d "${ORACLE_HOME}/oc4j/j2ee/OC4J_DBConsole_${DBHOST_NAME}_${ORACLE_DBNAME}" ]; then

	${ORACLE_HOME}/bin/emctl stop dbconsole
  # remove em console 
	# Fix if realy work!
	if [ "${CAN_CONNECT}" = "false" ]; then 
	 printError " Delete of Enterprise Manager not possible, DB not online"	
	else
		${ORACLE_HOME}/bin/emca -deconfig all db -silent -SID ${ORACLE_SID} -PORT 1521 -SYS_PWD ${SYS_USER_PWD} 
	fi
else
	printError "No Enterprise Manager enviroment detected under:"
	printError "${ORACLE_HOME}/oc4j/j2ee/OC4J_DBConsole_${DBHOST_NAME}_${ORACLE_DBNAME}"	
fi

# Remove old backups from DISK
printError "Clean old backups and archivelogs"

if [ "${CAN_CONNECT}" = "false" ]; then 
	printError "DB not online RMAN cannot be used for the deletion of old archivelogs or backups"
else

${ORACLE_HOME}/bin/rman<< EOScipt
		connect target /
		delete noprompt backup;
		delete noprompt archivelog all;
		exit;
EOScipt

fi


############### DROP DATABASE Command ###########################

# stop

printError "Shutdown the Database"

if [ "${RAC_ENV}" = "true" ]; then

TEST_CONNECT=`
    ${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
		alter system set cluster_database=false scope=spfile sid='*';
		exit	
EOScipt`

	printError "Try to stop the RAC Database ${ORACLE_DBNAME}"
	${ORACLE_HOME}/bin/srvctl stop database -d ${ORACLE_DBNAME} 

else 

TEST_CONNECT=`
    ${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
		shutdown abort
		exit	
EOScipt`
	if [ "$?" -ne "0" ]; then 
		printError "Can not connect to the Oracle database ${ORACLE_DBNAME}" 		
		printError "${TEST_CONNECT:0:40}...."
		CAN_CONNECT=false			
	else
	  printLineSuccess ${TEST_CONNECT}
		CAN_CONNECT=true
	fi
fi
	
if [ "${CAN_CONNECT}" = "true" ]; then 	
#Start restricted
printError "Start the Database in the restricted mode"

TEST_CONNECT=`
    ${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
		startup mount restrict force
		exit	
EOScipt`
	if [ "$?" -ne "0" ]; then 
		printError "Can not connect to the Oracle database ${ORACLE_DBNAME}" 		
		printError "${TEST_CONNECT:0:40}...."
		CAN_CONNECT=false			
	else
	  printLineSuccess ${TEST_CONNECT}
		CAN_CONNECT=true
	fi
#Drop database

printError "try to drop  the Database with sqlplus"
TEST_CONNECT=`
    ${ORACLE_HOME}/bin/sqlplus -s / as sysdba << EOScipt
		drop database;
		exit	
EOScipt`

	if [ "$?" -ne "0" ]; then 
		printError "Can not drop the the Oracle database ${ORACLE_DBNAME}" 		
		printError "${TEST_CONNECT:0:40}...."
		CAN_CONNECT=false			
	else
	  printLineSuccess ${TEST_CONNECT}
		CAN_CONNECT=true
	fi	
else
 	printError "Can not drop the the Oracle database ${ORACLE_DBNAME} - connect not possible" 		
fi	

# check that the DB is not running anymore
printLine "Check for running DB process for ora_smon_${ORACLE_SID}"
DB_SMON_PROCESS_ID=`ps -Af | grep ora_smon_${ORACLE_SID} | grep -v grep| wc -l`

if [ "${DB_SMON_PROCESS_ID}" = "1" ]; then
  printError "DB ${ORACLE_SID} is still running - Delete was not sucessfull"
	printError "Try to stop the DB manually"
	exit 1
fi


###########################################################################
printError "clean directories"
# clean Oracle Home directory 

# Oracle Home /dbs  init.ora and password file


ORA_DB_FILES[0]=${ORACLE_HOME}/dbs/hc_${ORACLE_DBNAME}.dat
ORA_DB_FILES[1]=${ORACLE_HOME}/dbs/init${ORACLE_DBNAME}.ora
ORA_DB_FILES[2]=${ORACLE_HOME}/dbs/lk${ORACLE_DBNAME}
ORA_DB_FILES[3]=${ORACLE_HOME}/dbs/orapw${ORACLE_DBNAME}
ORA_DB_FILES[4]=${ORACLE_HOME}/dbs/snapcf_${ORACLE_DBNAME}.f

if [ "${RAC_ENV}" = "true" ]; then

  typeset -i RAC_COUNTER=1	 

	for NODE in ${VIPNODES[@]}
		do		
			ORA_DB_FILES[0]=${ORACLE_HOME}/dbs/hc_${ORACLE_DBNAME}${RAC_COUNTER}.dat
			ORA_DB_FILES[1]=${ORACLE_HOME}/dbs/init${ORACLE_DBNAME}${RAC_COUNTER}.ora
			ORA_DB_FILES[2]=${ORACLE_HOME}/dbs/lk${ORACLE_DBNAME}${RAC_COUNTER}
			ORA_DB_FILES[3]=${ORACLE_HOME}/dbs/orapw${ORACLE_DBNAME}${RAC_COUNTER}
			ORA_DB_FILES[4]=${ORACLE_HOME}/dbs/snapcf_${ORACLE_DBNAME}${RAC_COUNTER}.f
			
			for ORA_DB_FILE in ${ORA_DB_FILES[@]}
			do
				ssh ${NODE} rm -f ${ORA_DB_FILE}	
				printLine  "delete file on ${NODE} :: ${ORA_DB_FILE}"							
			done
			RAC_COUNTER=RAC_COUNTER+1	
	done	
else	
	for ORA_DB_FILE in ${ORA_DB_FILES[@]}
		 do
		 if [ -f "${ORA_DB_FILE}" ]; then
			rm -f ${ORA_DB_FILE}			
			printLine  "delete file ${ORA_DB_FILE}"				
		fi	
	done
fi


# kill Enterprise Manager
# FIX Add Check if exists!
if [ "${RAC_ENV}" = "true" ]; then
	for NODE in ${VIPNODES[@]}
	do
			for ORA_DB_FILE in ${ORA_DB_FILES[@]}
			do
			ssh ${NODE} rm -f ${ORACLE_HOME}oc4j/j2ee/OC4J_DBConsole_${DBHOST_NAME}_${ORACLE_DBNAME}
			printLine  "delete file on ${NODE} :: ${ORA_DB_FILE}"			
		done
	done	
else	
	rm -f ${ORACLE_HOME}oc4j/j2ee/OC4J_DBConsole_${DBHOST_NAME}_${ORACLE_DBNAME}
fi	

# clean old controlfiles on disk/asm
# FIX ?? How to find ??
if [ "${ASM_ENV}" = "false" ]; then
	rm -rf ${ORACLE_BASE}/oradata/${ORACLE_DBNAME}
fi

# FIX Get List of File to delete!
# clean old redologs on disk/asm
if [ "${ASM_ENV}" = "false" ]; then
	rm -rf ${ORACLE_BASE}/oradata/${REDOLOG_DEST1}/${ORACLE_DBNAME}
  rm -rf ${ORACLE_BASE}/oradata/${REDOLOG_DEST2}/${ORACLE_DBNAME}
else
  setdb 1
  # create list of files for all asm disks
	ASM_DISKGROUP_LIST=`asmcmd -p ls`
	for group in $ASM_DISKGROUP_LIST
	do
	 asmcmd -p rm -rf $group/${ORACLE_DBNAME}
	done
fi
###########################################################################
# Remove from grid 

if [ "${RAC_ENV}" = "true" ]; then
 ${ORACLE_HOME}/bin/srvctl remove database -d ${ORACLE_DBNAME}
fi

# FIX it after test, can be combined  together with lines above
if [ "${ASM_ENV}" = "true" ]; then
  if [ ${RAC_ENV} = 'false' ]; then
		${ORACLE_HOME}/bin/srvctl remove database -d ${ORACLE_DBNAME} 
  fi	 
fi

###########################################################################

# Configure the enviroment 

if [ "${RAC_ENV}" = "true" ]; then
 	for NODE in ${VIPNODES[@]}
		do		
		printLineSuccess
		printLineSuccess  "Refresh configuration on this node => ${NODE}"			
		ssh ${NODE} ". .profile; setdbConfigure"				
		printLineSuccess
	done
else	
	setdbConfigure
fi

#############################################################################