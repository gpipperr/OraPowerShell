#!/bin/sh
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
#

# Parameter
ORACLE_HOME=$1
export ORACLE_HOME
ORACLE_SID=$2
export ORACLE_SID
ORACLE_DBNAME=$3
export ORACLE_DBNAME
NLS_LANG=$4
export NLS_LANG
# backupset destiation is set to ASM = rman will use automatic default and the flash recovery aera
# backupset destination is set to a directoy = rman parameter backupset format will be uses and backupset
# is wirtten ot this file location, for scenario only archivelogs are in the flash recovery area, backups on disk
BACKUPSET_DEST=$5
export BACKUPSET_DEST

# How many complet backups are on disk
BACKUP_REDUNDANCY=$6
export BACKUP_REDUNDANCY

#Destination of Archivelog Backup
ARCHIVELOG_BACKUPSET_DEST=$7
export ARCHIVELOG_BACKUPSET_DEST

# Test Parameter

if [ "$6" = ""  ]; then
   echo "Syntax: $f <ORACLE_HOME> <ORACLE_SID> <ORACLE_DBNAME> <NLS_LANG> <BACKUPSET_DEST [ASM|<directory>]> <BACKUP_REDANDENCY>"
   echo " "
   echo " "
   exit 2
fi
if [ ! -d $1 ]; then
   echo "Directory <ORACLE_HOME>=$1 not exist"
   echo " "
   exit 3
fi

#test only it backupset location is not on a ASM storage

if [ ! -d ${BACKUPSET_DEST}/${ORACLE_DBNAME} ]; then
 	echo "Backup SET Directory ${BACKUP_DEST}/${ORACLE_DBNAME} not exist"
	echo "create directory"
	echo " "
	mkdir ${BACKUPSET_DEST}/${ORACLE_DBNAME}
fi

if [ ! -d ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME} ]; then
 	echo "Backup SET Directory ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME} not exist"
	echo "create directory"
	echo " "
	mkdir ${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}
fi
  
if [  ${USE_FLASH} != "true" ]; then  
  if [ ! -d "${BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset" ]; then
    echo "Backup SET Directory ${BACKUP_DEST}/${ORACLE_DBNAME}/backupset not exist"
    echo "create directory"
    mkdir ${BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset 
  fi
  if [ ! -d "${BACKUPSET_DEST}/${ORACLE_DBNAME}/autobackup" ]; then
    echo "Backup SET Directory ${BACKUP_DEST}/${ORACLE_DBNAME}/autoback not exist"
    echo "create directory"
    mkdir ${BACKUPSET_DEST}/${ORACLE_DBNAME}/autobackup
 fi
 
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

#Test if database is running
DB_SMON_PROCESS_ID=`ps -Af | grep  ora_smon_$ORACLE_SID | grep -v grep| wc -l`
if [ "${DB_SMON_PROCESS_ID}" = "0" ]; then
  echo "Instance ${ORACLE_SID} is not running (No smon prozess in memory found)"
  echo " "
  exit 6
fi

## RMAN Backup is in runRMAN.sh

# Delete old Trace of Controlfile
#rm ${BACKUP_DEST}/${ORACLE_DBNAME}/controlfile_trace_${DAY_OF_WEEK}.trc

# Run Script to generate Trace of Controlfile
# Run Script to generate Copy of pfile
${ORACLE_HOME}/bin/sqlplus / as sysdba << EOScipt
ALTER DATABASE backup controlfile TO trace AS '${BACKUP_DEST}/${ORACLE_DBNAME}/controlfile_trace_${DAY_OF_WEEK}.trc' reuse;
CREATE pfile='${BACKUP_DEST}/${ORACLE_DBNAME}/init_${ORACLE_DBNAME}_${DAY_OF_WEEK}.ora' FROM spfile;
exit;
EOScipt

#Run Script to get DB Metadata Information
${ORACLE_HOME}/bin/sqlplus / as sysdba @${SCRIPTS}/info.sql

#PatchLevel of the database
$ORACLE_HOME/OPatch/opatch lsinventory > ${BACKUP_DEST}/${ORACLE_DBNAME}/software_lsinventory_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log

#Save Password File
cp ${ORACLE_HOME}/dbs/orapw${ORACLE_SID} ${BACKUP_DEST}/${ORACLE_DBNAME}/orapw${ORACLE_SID}_${DAY_OF_WEEK}
chmod 664 ${BACKUP_DEST}/${ORACLE_DBNAME}/orapw${ORACLE_SID}_${DAY_OF_WEEK}



