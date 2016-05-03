#!/bin/sh
# GPI Backup Start Script
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
#

########## Enviroment ##############
DAY_OF_WEEK="`date +%w`"
export DAY_OF_WEEK 

DAY="`date +%d`"
export DAY

# Home of the scrips
SCRIPTPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
SCRIPTS=`dirname "$SCRIPTPATH{}"`
export SCRIPTS


if [ ! -d ${SCRIPTS} ]; then
   echo "Scripts Directory ${SCRIPTS} not exist"
   echo "May be script not start in bash or over symlink?? "
   exit 1
fi

# Properties
declare -a DB_BACKUP
. ${SCRIPTS}/initbackup.conf

# Where to log
LOGS=${SCRIPTS}/log
export LOGS

# LOCK File
LOCKFILE=${SCRIPTS}/lck/lckbackup
export LOCKFILE

if [ ! -d ${BACKUP_DEST} ]; then
   echo "Backup Directory ${BACKUP_DEST} not exist"
   echo " "
   exit 2
fi

if [ ! -d ${SCRIPTS} ]; then
   echo "Script Directory ${SCRIPTS} not exist"
   echo " "
   exit 3
fi



#check if deftty is disabled
## FIX IST ###
# grep auf /etc/sudo and search after "defaults requiretty"
# check if on first position is a # with awk etc...

#check the nessesary sudo rights - only if grid is installed
if [ -f "${CRS_ASM_HOME}/bin/ocrcheck" ]; then 

	sudo -l  | grep "${CRS_ASM_HOME}/bin/ocrcheck" > /dev/null
	if [ "$?" -ne "0" ]; then 
		echo "sudo right on ${CRS_ASM_HOME}/bin/ocrcheck missing, please add with visudo!" 
		exit 4 
	fi 

	sudo -l  | grep "${CRS_ASM_HOME}/bin/ocrcheck.bin" > /dev/null
	if [ "$?" -ne "0" ]; then 
		echo "sudo right on ${CRS_ASM_HOME}/bin/ocrcheck.bin missing, please add with visudo!" 
		exit 4 
	fi

	sudo -l  | grep "${CRS_ASM_HOME}/bin/ocrconfig" > /dev/null
	if [ "$?" -ne "0" ]; then 
		echo "sudo right on ${CRS_ASM_HOME}/bin/ocrconfig missing, please add with visudo!" 
		exit 4 
	fi

	sudo -l  | grep "${CRS_ASM_HOME}/bin/ocrconfig.bin" > /dev/null
	if [ "$?" -ne "0" ]; then 
		echo "sudo right on ${CRS_ASM_HOME}/bin/ocrconfig.bin missing, please add with visudo!" 
		exit 4 
	fi

	sudo -l  | grep "${CRS_ASM_HOME}/bin/ocrdump" > /dev/null
	if [ "$?" -ne "0" ]; then 
		echo "sudo right on ${CRS_ASM_HOME}/bin/ocrdump missing, please add with visudo!" 
		exit 4 
	fi

	sudo -l  | grep "${CRS_ASM_HOME}/bin/ocrdump.bin" > /dev/null
	if [ "$?" -ne "0" ]; then 
		echo "sudo right on ${CRS_ASM_HOME}/bin/ocrdump.bin missing, please add with visudo!" 
		exit 4 
	fi
fi


sudo -l  | grep "/usr/bin/scp" > /dev/null
if [ "$?" -ne "0" ]; then 
  echo "sudo right on /usr/bin/scp missing, please add with visudo!" 
  exit 4 
fi

if [ -f "/usr/sbin/oracleasm" ]; then 
	sudo -l  | grep "/usr/sbin/oracleasm" > /dev/null
	if [ "$?" -ne "0" ]; then 
		echo "sudo right on /usr/sbin/oracleasm missing, please add with visudo!" 
		exit 4 
	fi
fi

#check for netapp tools
#if [ -f "/usr/sbin/sanlun" ]; then
# sudo -l  | grep "/usr/sbin/sanlun" > /dev/null
# if [ "$?" -ne "0" ]; then 
#   echo "sudo right on /usr/sbin/sanlun missing, please add with visudo" 
#   exit 4 
# fi
#  echo "Netapp Tools installed on this server - OK " 
#else
#  echo "Netapp Tools not installed on this server  - WRONG(test =>  /usr/sbin/sanlun missing, please install)" 
#fi

if [ -a ${LOCKFILE} ]; then
 echo "Backup may be still running - found lock file ${LOCKFILE} checking ..."

 LAST_RUN=`cat ${LOCKFILE}`
 AKT_RUN=`date +"%Y-%m-%d %k:%M"` 

 echo "Backup may be still running - found lock file ${LOCKFILE} for lastrun::${LAST_RUN} - act::${AKT_RUN}"

 COUNT_BACKUPS=`ps -Af | grep "/bin/sh ./runBackup.sh"  | grep -v "grep" | wc -l`

 echo "Count backups => ${COUNT_BACKUPS}"
 if [ "${COUNT_BACKUPS}" -gt "2" ]; then
   echo "Backup is really still running ......"
   exit 
  else
   echo "found old lck file , delete the file ${LOCKFILE}"
   /bin/rm ${LOCKFILE}
  fi 

fi

THIS_RUN=`date +"%Y-%m-%d %k:%M"`
echo ${THIS_RUN} > ${LOCKFILE}


echo ------------- START BACKUP V1 at "`date`" ----  -------------- > "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
echo Script $SCRIPTPATH is called in directory ${SCRIPTS}           >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1

##  Start Backup of the Meta Data of each DB
##  Parameter ORACLE_HOME ORACLE_SID ORACLE_DBNAME NLS_LANG BACKUPSET_LOCATION [ASM | <directory] BACKUP_REDUNDANCY
if [ "${BACKUP_DB_METADATA}" = "true"  ]; then 
	ELEMENT_COUNT=${#DB_BACKUP[@]}
	INDEX=0
	while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
	do    # List all the elements in the array.
		echo ------------- Start MetaData Backup at "`date`" ------------------   >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
		echo "start the Meta Data Backup for this Database  => ${DB_BACKUP[$INDEX]}" >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
		${SCRIPTS}/runDBMetaBackup.sh ${DB_BACKUP[$INDEX]}                         >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
		let "INDEX = $INDEX + 1"
	done
else
  echo "Paramter BACKUP_DB_METADATA is set to :: ${BACKUP_DB_METADATA}"          >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
  echo "NOT start the Metadata Backup for this Database  => ${DB_BACKUP[$INDEX]}" >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
fi

##  Start Backup for each DB
##  Parameter ORACLE_HOME ORACLE_SID ORACLE_DBNAME NLS_LANG BACKUPSET_LOCATION [ASM | <directory] BACKUP_REDUNDANCY
if [ "${BACKUP_DB}" = "true"  ]; then 
	ELEMENT_COUNT=${#DB_BACKUP[@]}
	INDEX=0
	while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
	do    # List all the elements in the array.
		echo ------------- Start Rman Backup at "`date`" ------------------   >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
		echo "start the DB Backup for this Database  => ${DB_BACKUP[$INDEX]}" >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1		
		${SCRIPTS}/runRMAN.sh ${DB_BACKUP[$INDEX]}                         >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
		let "INDEX = $INDEX + 1"
	done
else
  echo "Paramter BACKUP_DB is set to :: ${BACKUP_DB}"          >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
  echo "NOT start the Backup for this Database  => ${DB_BACKUP[$INDEX]}" >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
fi

##  Save Configuration of ASM Instance
##  Parameter ORACLE_HOME ORACLE_SID ORACLE_DBNAME NLS_LANG
if [ "${BACKUP_ASM}" = "true"  ]; then
	echo ------------- Start ASM Backup at "`date`" ------------------   >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
	${SCRIPTS}/backupASM.sh ${CRS_ASM_HOME} ${ASM_INSTANCESID} +ASM .UTF8  >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
fi

##  Save Configuration of GRID
##  Parameter ORACLE_HOME NLS_LANG
if [ "${BACKUP_GRID}" = "true"  ]; then
	echo ------------- Start GRID Backup at "`date`" ------------------   >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
	${SCRIPTS}/backupGRID.sh ${CRS_ASM_HOME}  .UTF8  >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1
fi

echo ------------- Finish BACKUP V1 at "`date`" ----  -------------- >> "${LOGS}/backup_${DAY_OF_WEEK}.log" 2>&1

/bin/rm ${LOCKFILE}

