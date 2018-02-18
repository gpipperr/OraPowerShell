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
# fix 12c if cluster is installed under other user
${ORACLE_HOME}/OPatch/opatch lsinventory -customLogDir /tmp  > ${BACKUP_DEST}/${CLUSTER_NAME}/software_lsinventory_${CLUSTER_NAME}_${DAY_OF_WEEK}.log

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
$ORACLE_HOME/bin/crsctl query css votedisk > ${BACKUP_DEST}/${CLUSTER_NAME}/location_of_vot_${CLUSTER_NAME}_${DAY_OF_WEEK}.log
#Save Backup of Voting Disk not longer necessary in 11g 

#Where is the OCR
sudo ${ORACLE_HOME}/bin/ocrcheck > ${BACKUP_DEST}/${CLUSTER_NAME}/location_of_ocr_${CLUSTER_NAME}_${DAY_OF_WEEK}.log


# save config files
# Exclude /etc/oracle/setasmgid
# Ignore the error at the moment
tar  zcvf --exclude=setasmgid --ignore-failed-read  ${BACKUP_DEST}/${CLUSTER_NAME}/sav_etc_oracle_${CLUSTER_NAME}_${DAY_OF_WEEK}.tar.gz /etc/oracle

# only if exits
if [ -d "/var/opt/oracle" ]; then 
	tar zcvf --exclude=setasmgid --ignore-failed-read  zcvf ${BACKUP_DEST}/${CLUSTER_NAME}/sav_var_opt_oracle_${CLUSTER_NAME}_${DAY_OF_WEEK}.tar.gz /var/opt/oracle/
fi

#save the wallet
# ?
# ----------- End of backupGrid.sh ------------
