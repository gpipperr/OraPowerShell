#!/user/bin/bash
# --delete zum syncronisieren
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
#

########## Enviroment ############
DAY_OF_WEEK="`date +%w`"
export DAY_OF_WEEK 

HOUR_RUN="`date +%H_%M`"
export HOUR_RUN

DAY="`date +%d`"
export DAY

# Where to log
LOGS=/tmp
export LOGS

SCRIPTS=/export/home/oracle/backup
export SCRIPTS

# LOCK File
LOCKFILEFULLB=${SCRIPTS}/lck/lckbackup
export LOCKFILEFULLB

LOCKFILEARCHIVE=${SCRIPTS}/lck/lckachive
export LOCKFILEARCHIVE

START_DATE=`date`

echo  "----------------------- Start : ${START_DATE} -------------------------------"         >> "${LOGS}/rsync_${DAY_OF_WEEK}.log" 2>&1

# check if the FUll Backup is running at the moment
if [ -a ${LOCKFILEFULLB} ]; then
	echo "-- Full Backup still running - found lock file ${LOCKFILEFULLB} ..."    >> "${LOGS}/rsync_${DAY_OF_WEEK}.log" 2>&1
	exit 1
fi

# check if the Archive Backup is running at the moment
if [ -a ${LOCKFILEARCHIVE} ]; then
	echo "-- Archive Backup still running - found lock file ${LOCKFILEARCHIVE} ..." >> "${LOGS}/rsync_${DAY_OF_WEEK}.log" 2>&1
	exit 1
fi	 

#######

#FIX 
# Solaris rsync => /opt/sfw/bin/rsync
# Linux
/usr/bin/rsync -av /opt/oracle/flash_recovery_area/ /ora_backup-nfs/DB100                 >> "${LOGS}/rsync_${DAY_OF_WEEK}.log" 2>&1


#########

END_DATE=`date`

echo  "-----------------------  End: ${END_DATE} -------------------------------"             >> "${LOGS}/rsync_${DAY_OF_WEEK}.log" 2>&1


