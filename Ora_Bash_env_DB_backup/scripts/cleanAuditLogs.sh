#!/bin/sh
# ######################################
#
#  Clean all audit log files  
#  www.pipperr.de
#  see https://www.pipperr.de/dokuwiki/doku.php?id=dba:oracle_rac_logfile_handling
#
# #####################################
# Crontab  
# 
# M H  D M
# Oracle clean Audit Logs
# 0 20 * * * /home/grid/scripts/cleanAuditLogs.sh > /tmp/crontab_start_clean_audit_log_job_grid.log
#
# #####################################


#DIRECTORY=/opt/oracle/admin/*
DIRECTORY=/u01/app/12.2.0.1/grid/rdbms/*


LOG_FILE=/tmp/aud_delete_logs_list_${USER}.log

echo "Info - start to analyses directory :  ${DIRECTORY}  - start at  -- `date` -- "    > $LOG_FILE

for d in $DIRECTORY
do
	 
	FILES=${d}/adump/*.aud
    TEST_DIR=${d}/adump

	
	echo "Info - +++++++++++++++++++++++++++++++++++++++++"    >> $LOG_FILE
	echo "Info - check the directory  :  ${FILES} "            >> $LOG_FILE
	
	if [ -d "${TEST_DIR}" ]; then
		
		# check the user for this home 
		# Grid owner or DB owner
		FILE_META=($(ls -ld  ${d} ))
		#OWNER
		FILE_OWNER="${FILE_META[2]}" 
		
		echo "Info - Owner of ${d} is ${FILE_OWNER}"            >> $LOG_FILE
	  
		if [[ ${USER} = ${FILE_OWNER} ]]; then
		
		
			DATE_NOW_EPOCH=`date +%s`
			#Get the epoch 6 Month ago
			DATE_DELETE_OLDER=`date --date "now -6 months" +"%s"`
		 
			echo "Info -  Found `ls ${TEST_DIR} | wc -l` files in ${TEST_DIR}" >> $LOG_FILE
			
			echo "Info - check the age of the file - start at  -- `date` -- " >> $LOG_FILE
						
			for f in $FILES
			do
			  #File date as epoch 
			  FILE_DATE=`stat -c %Y ${f}`              >> $LOG_FILE  2>&1
			  FILE_LOG_DATE=`stat -c %y ${f}`          >> $LOG_FILE  2>&1
			  
			  if [[ ${FILE_DATE} -lt ${DATE_DELETE_OLDER} ]];
			  then
			   echo "Info - delete :: ${FILE_LOG_DATE} ${f}"  >> $LOG_FILE 
			   rm ${f}                                        >> $LOG_FILE  2>&1
			  fi
			
			done
			 
			echo "Info - finish with ${FILES} at     -- `date` -- "        >> $LOG_FILE
			
		
		else
		
		   echo "Warning - Can not delete files from other user ${FILE_OWNER} as user  ${USER}"        >> $LOG_FILE
		fi
		
		
	else
	   echo "Warning - directory ${TEST_DIR} not exists"                  >> $LOG_FILE
	fi	
	
	echo "Info - +++++++++++++++++++++++++++++++++++++++++"        >> $LOG_FILE
	
done	

echo "Info - finish at  -- `date` -- "        >> $LOG_FILE
