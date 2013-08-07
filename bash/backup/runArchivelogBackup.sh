#!/bin/sh
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
#
#  /home/oracle/backup/runArchivelogBackup.sh
#
#
#  # archive every  hour - crontab entry
#  30 * * * * /home/oracle/backup/runArchivelogBackup.sh
#
#
# NOT BACKED UP 1 TIMES or DELETE?

setEnv(){
	ORACLE_HOME=$1
	export ORACLE_HOME
	ORACLE_SID=$2
	export ORACLE_SID
	ORACLE_DBNAME=$3
	export ORACLE_DBNAME
	NLS_LANG=$4
	export NLS_LANG
	BACKUPSET_DEST=$5
	export BACKUPSET_DEST
	ARCHIVELOG_BACKUPSET_DEST=$7
	export ARCHIVELOG_BACKUPSET_DEST
}

##################################

. /home/oracle/.profile

########## Enviroment ############
DAY_OF_WEEK="`date +%w`"
export DAY_OF_WEEK 

HOUR_RUN="`date +%H_%M`"
export HOUR_RUN

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
LOCKFILEFULLB=${SCRIPTS}/lck/lckbackup
export LOCKFILEFULLB

LOCKFILEARCHIVE=${SCRIPTS}/lck/lckachive
export LOCKFILEARCHIVE


START_DATE=`date`

if [ "`date +%H`" -lt 1 ]; then
	echo "----------------------- start new Day ${DAY_OF_WEEK} -------------------------------" > "${LOGS}/archive_${DAY_OF_WEEK}.log" 2>&1
fi

echo  "----------------------- Start : ${START_DATE} -------------------------------"         >> "${LOGS}/archive_${DAY_OF_WEEK}.log" 2>&1

# check if the FUll Backup is running at the moment
if [ -a ${LOCKFILEFULLB} ]; then
	echo "Full Backup still running - found lock file ${LOCKFILEFULLB} ..."
	exit 1
fi

# check if the Archive Backup is running at the moment
if [ -a ${LOCKFILEARCHIVE} ]; then
	echo "Archive Backup still running - found lock file ${LOCKFILEARCHIVE} ..."
	exit 1
else
 	touch ${LOCKFILEARCHIVE}
fi	 

# create the Archivebackup



## start the Archivebackup
##  Start Archivebackup for each DB if parameter BACKUP_DB_ARCHIVELOGS is true
##  Parameter ORACLE_HOME ORACLE_SID ORACLE_DBNAME NLS_LANG BACKUPSET_LOCATION [ASM | <directory] BACKUP_REDUNDANCY

if [ "${BACKUP_DB_ARCHIVELOGS}" = "true"  ]; then 
	ELEMENT_COUNT=${#DB_BACKUP[@]}
	INDEX=0
	while [ "${INDEX}" -lt "${ELEMENT_COUNT}" ]
	do    # List all the elements in the array.
		echo "start the Archivelog Backup for this Database  => ${DB_BACKUP[$INDEX]}" >> "${LOGS}/archive_${DAY_OF_WEEK}.log" 2>&1
		setEnv ${DB_BACKUP[$INDEX]}
		
		#test only it backupset location is not on a ASM storage

		if [ ! -d ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME} ]; then
			echo "Backup SET Directory ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME} not exist"
			echo "create directory"
			echo " "
			mkdir ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}
		fi
			
		if [  ${USE_FLASH} != "true" ]; then  
			if [ ! -d "${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset" ]; then
				echo "Backup SET Directory ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset not exist"
				echo "create directory"
				mkdir -p ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset 
			fi
			if [ ! -d "${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/autobackup" ]; then
				echo "Backup SET Directory ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/autoback not exist"
				echo "create directory"
				mkdir -p ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/autobackup
		 fi 
		fi

	
		##check Version of Database
			VERVIEW=\$version
			ISENTERISE=`echo "set pagesize 0 
			set feedback off
			select count(*) from v_${VERVIEW} where banner like '%Enterprise%';
			quit"|${ORACLE_HOME}/bin/sqlplus -s / as sysdba`

			#echo "check DB Version - Get 1 for EE and 0 for SE - Result is ${ISENTERISE}" 

			if [ ${ISENTERISE} -eq 1 ] 
			then
				## compression
				COMPRESSION="AS COMPRESSED BACKUPSET"		
			fi;
		
		 echo "#Backup archivelogs "												 >  ${SCRIPTS}/archivelogDelete.rman
		
		 if [ ${USE_FLASH} = "true" ]; then
				echo "CONFIGURE CHANNEL DEVICE TYPE DISK clear;"                               >>  ${SCRIPTS}/archivelogDelete.rman
				echo "CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK clear;"     >>  ${SCRIPTS}/archivelogDelete.rman
			else
				echo "CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset/%U';"                        >>  ${SCRIPTS}/archivelogDelete.rman
				echo "CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK to '${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/autobackup/%F';" >>  ${SCRIPTS}/archivelogDelete.rman
			fi
			
			echo "SQL \"alter system archive log current\";"	>>  ${SCRIPTS}/archivelogDelete.rman
			echo "backup ${COMPRESSION} archivelog ALL tag \"ARCHIVE_DAY${DAY_OF_WEEK}_${HOUR_RUN}\" DELETE INPUT;"	      >>  ${SCRIPTS}/archivelogDelete.rman
		
		
		${ORACLE_HOME}/bin/rman target / nocatalog @${SCRIPTS}/archivelogDelete.rman  >> "${LOGS}/archive_${DAY_OF_WEEK}.log" 2>&1
		
		let "INDEX = $INDEX + 1"
	done
fi

END_DATE=`date`

echo  "-----------------------  End: ${END_DATE} -------------------------------"  >> "${LOGS}/archive_${DAY_OF_WEEK}.log" 2>&1

/bin/rm ${LOCKFILEARCHIVE}

