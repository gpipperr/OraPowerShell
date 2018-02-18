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
	# sectionsize for big tablespace
	SECTIONSIZE="SECTION SIZE 5000M"
	#PARALLELISM
	PARALLELISM="PARALLELISM 2"
fi;


# Run RMAN Script for this DB if EE incremental - SE only full
if [ ${ISENTERISE} -eq 1 ] 
then
	case "${DAY_OF_WEEK}" in
			0)
					INC_LEVEL="0"
					;;
			1)
					INC_LEVEL="1" 
					;;
			2)
					INC_LEVEL="2" 
					;;
			3)
					INC_LEVEL="3" 
					;;
			4)
					INC_LEVEL="1" 
					;;
			5)
					INC_LEVEL="1"
					;;
			6)
					INC_LEVEL="2"
					;;
			*)
				 exit 5
				 ;;
	esac    
else
	INC_LEVEL="0"
fi;

echo "Start Backup increment level ${INC_LEVEL} of ${ORACLE_DBNAME} from instance ${ORACLE_SID} ...."
echo "Use Backup format :: ${BACKUP_FORMAT_COMMAND} "

#generate the rman script

echo "#configuration"     										>  ${SCRIPTS}/generated.rman

#configuration rman backup
if [ ${USE_FLASH} = "true" ]; then
 echo "CONFIGURE CHANNEL DEVICE TYPE DISK clear;"                               >>  ${SCRIPTS}/generated.rman
 echo "CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK clear;"     >>  ${SCRIPTS}/generated.rman
else
 echo "CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset/%U';"                        >>  ${SCRIPTS}/generated.rman
 echo "CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK to '${BACKUPSET_DEST}/${ORACLE_DBNAME}/autobackup/%F';" >>  ${SCRIPTS}/generated.rman
fi

echo "CONFIGURE CONTROLFILE AUTOBACKUP ON;" 	>>  ${SCRIPTS}/generated.rman
echo "CONFIGURE DEVICE TYPE DISK ${PARALLELISM} BACKUP TYPE TO BACKUPSET;"  >>  ${SCRIPTS}/generated.rman
echo "# configure redundancy"  												>>  ${SCRIPTS}/generated.rman
echo "CONFIGURE RETENTION POLICY TO REDUNDANCY ${BACKUP_REDUNDANCY};" 		>>  ${SCRIPTS}/generated.rman
echo "SHOW ALL;"								>>  ${SCRIPTS}/generated.rman
echo ""											>>  ${SCRIPTS}/generated.rman
echo "# test old backup "						>>  ${SCRIPTS}/generated.rman
echo "crosscheck datafilecopy all;"				>>  ${SCRIPTS}/generated.rman
echo "crosscheck backup;"						>>  ${SCRIPTS}/generated.rman
echo "delete noprompt EXPIRED backup;"			>>  ${SCRIPTS}/generated.rman
echo "crosscheck archivelog all;"				>>  ${SCRIPTS}/generated.rman
echo "DELETE noprompt EXPIRED archivelog all;"	>>  ${SCRIPTS}/generated.rman
echo ""											>>  ${SCRIPTS}/generated.rman
echo "#Backup DB"								>>  ${SCRIPTS}/generated.rman
echo "SQL \"alter system checkpoint\";  "		>>  ${SCRIPTS}/generated.rman
echo "backup incremental LEVEL ${INC_LEVEL} tag \"DB_LEVEL${INC_LEVEL}_DAY${DAY_OF_WEEK}\" ${COMPRESSION} ${SECTIONSIZE} DATABASE;"	>>  ${SCRIPTS}/generated.rman
echo ""											>>  ${SCRIPTS}/generated.rman


if [ ${USE_FLASH} = "true" ]; then
		echo "CONFIGURE CHANNEL DEVICE TYPE DISK clear;"                                                                             >>  ${SCRIPTS}/generated.rman
	else
		echo "CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${ARCHIVELOG_BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset/%U';"               >>  ${SCRIPTS}/generated.rman
fi

echo "#Backup archivelogs "						>>  ${SCRIPTS}/generated.rman
echo "SQL \"alter system archive log current\";"	>>  ${SCRIPTS}/generated.rman
echo "backup ${COMPRESSION} archivelog ALL tag \"ARCHIVE_DAY${DAY_OF_WEEK}\" DELETE INPUT;"	>>  ${SCRIPTS}/generated.rman
echo ""											>>  ${SCRIPTS}/generated.rman


echo "#Delete old Backups"						>>  ${SCRIPTS}/generated.rman
echo "delete noprompt obsolete;"				>>  ${SCRIPTS}/generated.rman
echo ""											>>  ${SCRIPTS}/generated.rman

echo "#Backup controlfile and spfile "			>>  ${SCRIPTS}/generated.rman

if [ ${USE_FLASH} = "true" ]; then
 echo "CONFIGURE CHANNEL DEVICE TYPE DISK clear;"                               >>  ${SCRIPTS}/generated.rman
 echo "CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK clear;"     >>  ${SCRIPTS}/generated.rman
else
 echo "CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${BACKUPSET_DEST}/${ORACLE_DBNAME}/backupset/%U';"                        >>  ${SCRIPTS}/generated.rman
 echo "CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK to '${BACKUPSET_DEST}/${ORACLE_DBNAME}/autobackup/%F';" >>  ${SCRIPTS}/generated.rman
fi

echo "backup current controlfile tag \"CONTROLFILE_DAY${DAY_OF_WEEK}\";"	>>  ${SCRIPTS}/generated.rman
echo "backup spfile tag \"SPFILE_DAY${DAY_OF_WEEK}\";"				>>  ${SCRIPTS}/generated.rman
echo ""											>>  ${SCRIPTS}/generated.rman
echo "#Summary info"							>>  ${SCRIPTS}/generated.rman
echo "list backup summary;"						>>  ${SCRIPTS}/generated.rman
echo " "										>>  ${SCRIPTS}/generated.rman

#start the backup script for this day
${ORACLE_HOME}/bin/rman target / nocatalog @${SCRIPTS}/generated.rman

echo ------------- Finish Rman Backup at "`date`" ------------------
#
# The meta data backup is moved to runDBMetaBackup.sh
#
# Save new backupsets to disk
# use only if asm is archive and rman backup destination

if [  ${BACKUP_FLASH_TO_DISK} = "true" ]; then
	echo ------------- Start Backup Flash Recovery Area at "`date`" ------------------
	if [ ${ISENTERISE} -eq 1 ] 
	then
		#use backup OPTIMIZATION 
		${ORACLE_HOME}/bin/rman target / nocatalog @${SCRIPTS}/backup_flash.rman USING "'${BACKUP_DEST}/${ORACLE_DBNAME}'"
	else
		#not use backup OPTIMIZATION 
		${ORACLE_HOME}/bin/rman target / nocatalog @${SCRIPTS}/backup_flash_se.rman USING "'${BACKUP_DEST}/${ORACLE_DBNAME}'"
	fi
	echo ------------- Finish Backup Flash Recovery Area at "`date`" ------------------
fi

