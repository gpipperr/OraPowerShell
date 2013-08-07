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
NLS_LANG=$2
export NLS_LANG

# Test Parameter
if [ "$2" = ""  ]; then
   echo "Syntax: $f <ORACLE_HOME> <NLS_LANG>"
   echo " "
   echo " "
   exit 2
fi
if [ ! -d $1 ]; then
   echo "Directory <ORACLE_HOME>=$1 not exist"
   echo " "
   exit 3
fi

CLUSTER_NAME=`${ORACLE_HOME}/bin/cemutlo -n`
export CLUSTER_NAME

if [ ! -d ${BACKUP_DEST}/${CLUSTER_NAME} ]; then
   echo "Backup Directory ${BACKUP_DEST}/${CLUSTER_NAME} not exist"
   echo ".. creating directory "
   mkdir ${BACKUP_DEST}/${CLUSTER_NAME}
fi

#PatchLevel of the grid
${ORACLE_HOME}/OPatch/opatch lsinventory > ${BACKUP_DEST}/${CLUSTER_NAME}/software_lsinventory_${CLUSTER_NAME}_${DAY_OF_WEEK}.log

#Save ocr
echo "Make a backup of the ocr and Voting Disk"
sudo ${ORACLE_HOME}/bin/ocrconfig -manualbackup

#Save OCR AutoBackups
#get all nodes
NODES=`${ORACLE_HOME}/bin/srvctl status nodeapps | grep 'VIP' | grep 'on node' | awk '{ print $7 }'`
export NODES

for NODE in $NODES
do
	echo "copy ocr from $NODE ...."
	if [ ! -d ${BACKUP_DEST}/${CLUSTER_NAME}/${NODE} ]; then
	   mkdir ${BACKUP_DEST}/${CLUSTER_NAME}/${NODE}
	   echo "create Backup Directory for node ${NODE}"
	fi
	echo -- try to save =root@${NODE}:${ORACLE_HOME}/cdata/${CLUSTER_NAME}/*.ocr  ${BACKUP_DEST}/${CLUSTER_NAME}/${NODE}
	sudo scp -p root@${NODE}:${ORACLE_HOME}/cdata/${CLUSTER_NAME}/*.ocr  ${BACKUP_DEST}/${CLUSTER_NAME}/${NODE}
done

#Save OCR Regitry Infos
$ORACLE_HOME/bin/ocrdump -stdout > ${BACKUP_DEST}/${CLUSTER_NAME}/ocr_${CLUSTER_NAME}_${DAY_OF_WEEK}.dump

#Where is the voting Disk?
$ORACLE_HOME/bin/crsctl query css votedisk > ${BACKUP_DEST}/${CLUSTER_NAME}/location_of_ocr_${CLUSTER_NAME}_${DAY_OF_WEEK}.log

#Save Backup of Voting Disk not longer necessary in 11g 
