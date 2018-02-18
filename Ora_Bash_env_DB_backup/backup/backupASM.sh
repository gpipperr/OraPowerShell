#!/bin/sh
# Parameter
#
# Part of the Gunther Pippèrr 
#  GPI Oracle Script Library
#  for more information see:   http://orapowershell.codeplex.com
#
#

ORACLE_HOME=$1
export ORACLE_HOME
ORACLE_SID=$2
export ORACLE_SID
ORACLE_DBNAME=$3
export ORACLE_DBNAME
NLS_LANG=$4
export NLS_LANG
# Test Parameter

if [ "$4" = ""  ]; then
   echo "Syntax: $f <ORACLE_HOME> <ORACLE_SID> <ORACLE_DBNAME> <NLS_LANG>"
   echo " "
   echo " "
   exit 2
fi
if [ ! -d $1 ]; then
   echo "Directory <ORACLE_HOME>=$1 not exist"
   echo " "
   exit 3
fi

if [ ! -d ${BACKUP_DEST}/${ORACLE_DBNAME} ]; then
   echo "Backup Directory ${BACKUP_DEST}/${ORACLE_DBNAME} not exist"
   echo ".. creating directory "
   mkdir ${BACKUP_DEST}/${ORACLE_DBNAME}
   chmod 776 ${BACKUP_DEST}/${ORACLE_DBNAME}
fi

if [ ! "$3" = "+ASM" ]; then
   echo "only valid to  save +ASM Configuration"
   echo " "
   exit 5
fi

# Run Script to generate Trace of Controlfile
# Run Script to generate Copy of pfile
#
${ORACLE_HOME}/bin/sqlplus / as sysasm << EOScipt
CREATE pfile='${BACKUP_DEST}/${ORACLE_DBNAME}/init_${ORACLE_DBNAME}_${DAY_OF_WEEK}.ora' FROM spfile;
exit;
EOScipt

#Run Script to get DB Metadata Information
#
${ORACLE_HOME}/bin/sqlplus / as sysasm @${SCRIPTS}/infoASM.sql

#PatchLevel of the database
#
$ORACLE_HOME/OPatch/opatch lsinventory > ${BACKUP_DEST}/${ORACLE_DBNAME}/software_lsinventory_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log

#Save Password File
#
if [ -f "${ORACLE_HOME}/dbs/orapw${ORACLE_SID}" ]; then
	echo "-- Info : save PWD file from File => ${ORACLE_HOME}/dbs/orapw${ORACLE_SID}"
	cp ${ORACLE_HOME}/dbs/orapw${ORACLE_SID} ${BACKUP_DEST}/${ORACLE_DBNAME}/orapw${ORACLE_DBNAME}_${DAY_OF_WEEK}
fi
# Fix PWD file from ASM!

# get the ASM PWD NAME
ASM_PWD_NAME=`${ORACLE_HOME}/bin/asmcmd pwget --asm`
echo "-- Info : save PWD file from ASM => ${ASM_PWD_NAME}"

# fist remove
rm -f ${BACKUP_DEST}/${ORACLE_DBNAME}/orapw_ASM_${DAY_OF_WEEK}

# debug 
# echo "-- Info : try to copy PWD file from ASM with ${ORACLE_HOME}/bin/asmcmd pwcopy --asm ${ASM_PWD_NAME} ${BACKUP_DEST}/${ORACLE_DBNAME}/orapw_ASM_${DAY_OF_WEEK}"
${ORACLE_HOME}/bin/asmcmd pwcopy --asm ${ASM_PWD_NAME} ${BACKUP_DEST}/${ORACLE_DBNAME}/orapw_ASM_${DAY_OF_WEEK}

#Save Disk and Directroy Configuration
#
rm  ${BACKUP_DEST}/${ORACLE_DBNAME}/asm_configuration${ORACLE_SID}_${DAY_OF_WEEK}.trc

${ORACLE_HOME}/bin/asmcmd md_backup -b ${BACKUP_DEST}/${ORACLE_DBNAME}/asm_configuration${ORACLE_SID}_${DAY_OF_WEEK}.trc
# save the lun configuration of the node1
#
echo "----=== Layout of ASM to physikal disks ===---"  >  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log
echo " "  >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log 

ls -la /dev/oracleasm/disks/* >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log

echo "---=== ASM to OS Disk Layout ===---" >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log

# Get the Oracle ASM to os disk mapping
for DISK in `ls -m1 /dev/oracleasm/disks/`
do
 majorminor=`sudo /usr/sbin/oracleasm querydisk -d $DISK | awk '{print $10 $11}' | tr -d '[]' | tr ',' ' ' `
 major=`echo $majorminor | awk '{print $1}'`
 minor=`echo $majorminor | awk '{print $2}'`
 device=`ls -l /dev | awk '{print $5 " "  $6 "- "  $10}' |  grep "$major, $minor-" | awk '{print $3}'`
 echo "Oracle ASM Disk Device: $DISK	=>  OS device: /dev/$device     with id $majorminor"  >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log 
done

echo " " >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log
echo "---=== LUN Mapping ===---" >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log


#edit this line to your tool of your storage 
#for netapp

if [ ! -f "/usr/sbin/sanlun" ]; then
  #echo "Netapp Tools not exist"
  #echo " "   
  # check the ASM Disks
  echo "---=== spool blkid ===---" >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log
  sudo /usr/sbin/blkid | grep asm >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log
  echo "---=== spool lsblk ===---" >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log
  sudo /usr/bin/lsblk -o TYPE,MAJ:MIN,WWN,HCTL,NAME,SIZE | grep disk   >> ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log
else
  sudo /usr/sbin/sanlun lun show -p >>  ${BACKUP_DEST}/${ORACLE_DBNAME}/asmdisks_lun_config_${ORACLE_DBNAME}_${DAY_OF_WEEK}.log	 
fi




