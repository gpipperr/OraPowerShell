#!/bin/sh
# ######################################
#
#  Purge DIAG HOMES 
#  www.pipperr.de
#  see https://www.pipperr.de/dokuwiki/doku.php?id=dba:oracle_rac_logfile_handling
#
# #####################################
# Crontab  
# 
# M H  D M
# Oracle purge  DIAG Logs
# 0 20 * * * /home/grid/scripts/cleanDiagHome.sh  > /tmp/crontab_start_clean_diag_home_job_grid.log
#
# #####################################

#set the enviroment to the ${USER} home
source /home/${USER}/.profile

# set the home switch to the current user!
# Set this for each installation
setdb 1 > /dev/null 2>&1

# Fill out the diag home
# Set this for each installation
DIAG_HOME=/opt/oracle/

# write log
LOG_FILE=/tmp/diag_delete_log_${USER}.log

#  set rentation policy days
# 263520= 183 days
# Set this for each installation
MINUTES=263520


echo "Info - start to analyses all DIAG Homes  - start at  -- `date` -- "       > $LOG_FILE
echo "Info - clean all 12c homes after for files older than ${MINUTES} minutes"  >> $LOG_FILE

for a in $(adrci exec="show homes" | grep diag)
do
      
   
    echo "Info - Info purge Log for Home  ${a}"         >> $LOG_FILE
  
    # check the user for this home 
    # Grid owner or DB owner
	FILE_META=($(ls -ld  $DIAG_HOME/${a} ))
	#OWNER
	FILE_OWNER="${FILE_META[2]}" 
	
	echo "Info - Owner of ${a} is ${FILE_OWNER}"            >> $LOG_FILE
  
    if [[ ${USER} = ${FILE_OWNER} ]]; then
	
	   #   set the Long policy and check
       #    adrci exec="set home ${a}; set control \( LONGP_POLICY=4392 \) ;"   >> $LOG_FILE  2>&1
       #    adrci exec="set home ${a}; select SHORTP_POLICY,LONGP_POLICY,LAST_AUTOPRG_TIME from ADR_CONTROL ;"   >> $LOG_FILE  2>&1
      
	  
		adrci exec="set home ${a}; purge -age ${MINUTES} ;"   >> $LOG_FILE  2>&1

     else
	
	   echo "Warning - Can not clean ADR files from other user ${FILE_OWNER} as user ${USER}"        >> $LOG_FILE
	   
     fi	 
  
done

echo "Info - finish at  -- `date` -- "                >> $LOG_FILE

