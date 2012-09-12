#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Library for the backup scripts 
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================
<#

  
	.NOTES
		Created: 08.2012 : Gunther Pippèrr (c) http://www.pipperr.de
		Security:
		(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
		To switch it off (as administrator)
		get-Executionpolicy -list
		set-ExecutionPolicy -scope CurrentUser RemoteSigned
		or
		sign scripts!
  		
	.SYNOPSIS
		Generic functions for backup
		
	.DESCRIPTION
		Generic functions for backup
		
	.COMPONENT
		Oracle Backup Script

#>

#==============================================================================
# Check if DB Backup Directory exists
###

function local-check-all-directories {
		Param ( $DB ) # end Param
		
	$check_path= $dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()
	$check_result=local-check-dir -lcheck_path $check_path -dir_name "DB Backup"
	
	# Check if Archive Backup Directory exists
	$check_path= $dB.archive_backup_dest.ToString()+"\"+$dB.dbname.ToString()
	$check_result=local-check-dir -lcheck_path $check_path -dir_name "Archive Backup"
    
	# check if the default directories exists (ony if we not using the flash area over the flash_recovery_parameter)
	if ($db.db_backup_use_flash.equals("false")) {
		#Check if the default structure is on disk
		
		# DB Backups
		$check_path= $dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\backupset"
		$check_result=local-check-dir -lcheck_path $check_path -dir_name "DB Backupset"
		
		$check_path= $dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\autobackup"
		$check_result=local-check-dir -lcheck_path $check_path -dir_name "DB Autobackup"
		
		# Archivelog Backups
		$check_path= $dB.archive_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\backupset"
		$check_result=local-check-dir -lcheck_path $check_path -dir_name "Archive Backupset"
		
		$check_path= $dB.archive_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\autobackup"
		$check_result=local-check-dir -lcheck_path $check_path -dir_name "Archive Autobackup" 
	}

}
#==============================================================================
function local-check-connect{
	Param (   $sql_connect_string  = "/ as sysdba"			
	) #end param
	try {
			local-print  -Text "Info -- check if Oracle SID is accessible ::" , $env:ORACLE_SID
		
			# test Connect to the datbase
			# must be on first line
$check_db=@'
set pagesize 0 
set feedback off
select count(*) from v$instance;
quit
'@| & "$env:ORACLE_HOME\bin\sqlplus" -s "$sql_connect_string"

			# if check_db is not a string is is mostly a error return from sql*plus
			# trim on [] will cause the exection
			try{
				$check_db=$check_db.trim()
				local-print  -Text "Info -- check successful for  SID ::" , $env:ORACLE_SID
				$can_connect="true"
			}
			catch {
				local-print -ForegroundColor "red"  -Text "Error--",$check_db
				local-log-event -logtype "Error" -logText "Error-- Can not connect to instance : The error was: $check_db."
				$can_connect="false"
			}
			
		}
		catch {
			local-print -ForegroundColor "red"  -Text "Error-- Can not connect to instance : The error was: $_."				
			local-log-event -logtype "Error" -logText "Error-- Can not connect to instance : The error was: $_."
			$can_connect="false"
		}
		
	return $can_connect
}



#==============================================================================

function local-backup-database {
	Param (   $db 
			, $sql_connect_string  = "/ as sysdba"
			, $rman_connect_string = "/"
	) #end param
    
    $starttime=get-date
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
	local-print  -Text "Info -- Start Backup DB Files of DB::", $DB.dbname ,"at::", $starttime ," Day of Week::" ,$day_of_week  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Start Backup DB Files of DB::", $DB.dbname ,"at::", $starttime ," Day of Week::" ,$day_of_week
		
	$ORACLE_HOME=$dB.oracle_home.ToString()
	$ORACLE_SID=$dB.sid.ToString()
	
	# Check if the backup directories exits
	local-check-all-directories($DB)
	
	
	##check Version of Database
	# Must be on the first line!!
$isenterprise=@'
set pagesize 0 
set feedback off
select count(*) from v$version where banner like '%Enterprise%';
quit
'@| & "$ORACLE_HOME/bin/sqlplus" -s "$sql_connect_string"
		
	$isenterprise=$isenterprise.Trim()

	local-print  -Text "Info -- check DB Version - Get 1 for EE and 0 for SE - Result is ::" ,$isenterprise

	# Optimize the backup for Enterprise features
	#
	$compression=""
	# sectionsize for big tablespace
	$sectionsize=""
	#PARALLELISM
	$parallelism=""
	
	if ($isenterprise -eq 1) {
		#read the EE parameter section
		## compression
		$use_compression=$dB.db_backup_compress.toString();
		if ($use_compression.equals("true")) {
			$compression="AS COMPRESSED BACKUPSET"
		}
		$sectionsize=$dB.db_backup_section_size.toString();
		# sectionsize for big tablespace
		if ( ! $use_compression.equals("false")) {
			$sectionsize="SECTION SIZE "+$sectionsize
		}
		#PARALLELISM
		$parallelism=$dB.db_backup_channels.toString();
		$parallelism="PARALLELISM "+$parallelism
	}
		
	# Run RMAN Script for this DB if EE incremental - SE only full
	# Weekly based incremental routine!
	$inc_level="0"
	if ($isenterprise -eq 1) {
		# read Incremental Policy
		$inc_policy=$dB.db_backup_incremental_policy.toString();
		local-print  -Text "Info -- Read Incremental Policy",$inc_policy
		#
		try {
			$apolicy=$inc_policy.Split(",")
			#
			if ( $apolicy.Length -eq 7 ) {
				$inc_level=$apolicy[$day_of_week-1]
				local-print  -Text "Info -- Set Export Policy for day of week",$day_of_week ,"to" , $inc_level
			}
			else {
				local-print  -Text "Error -- Export Policy is not correct! Using the default Policy - Export Policy::" ,$inc_policy -ForegroundColor "red"
				# hold the last two export on disk, and hold one export for one week
				switch ($day_of_week) {
					1 {$inc_level="1" }
					2 {$inc_level="1" }
					3 {$inc_level="2" }
					4 {$inc_level="1" }
					5 {$inc_level="1"}
					6 {$inc_level="2"}
					7 {$inc_level="0"}
					default 
					  {$inc_level="0"}
				} 
			}
		}
		catch {
			$inc_level="0"
			local-print  -Text "Error -- Export Policy is not correct! Fix the error - Error::" ,$_ -ForegroundColor "red"
		}			
	}	

	local-print  -Text "Info -- Generate Backup Script with the increment level ", $inc_level ," of ", $dB.dbname.ToString(), " from instance " , $ORACLE_SID ,"...."

	#generate the rman script
	$rman_script ="#configuration" + $CLF 

	#configuration rman backup
	if ($db.db_backup_use_flash.equals("true")) {
		$rman_script +="CONFIGURE CHANNEL DEVICE TYPE DISK clear;"                           +$CLF 
		$rman_script +="CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK clear;" +$CLF 
	}
	else {
		$check_path   = $dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\backupset\%U"
		$rman_script +="CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '" + $check_path + "';"  +$CLF 
		$check_path   = $dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\autobackup\%F"
		$rman_script +="CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK to '" + $check_path + "';" +$CLF 
	}

	$rman_script +="CONFIGURE CONTROLFILE AUTOBACKUP ON;" 	+$CLF 
	$rman_script +="CONFIGURE DEVICE TYPE DISK "+$parallelism+" BACKUP TYPE TO BACKUPSET;"+$CLF 
	
	$rman_script +="# configure redundancy"+$CLF 
	$backup_redundancy = $db.db_backup_count_of.ToString()
	$rman_script +="CONFIGURE RETENTION POLICY TO REDUNDANCY "+ $backup_redundancy+";" 	+$CLF 
	$rman_script +="SHOW ALL;"+$CLF 
	$rman_script +=$CLF 
	
	$rman_script +="#test old backup "						    +$CLF 
	$rman_script +="crosscheck datafilecopy all;"				+$CLF 
	$rman_script +="crosscheck backup;"						    +$CLF 
	$rman_script +="delete noprompt EXPIRED backup;"			+$CLF 
	$rman_script +="crosscheck archivelog all;"				    +$CLF 
	$rman_script +="DELETE noprompt EXPIRED archivelog all;"	+$CLF 
	$rman_script +=$CLF 
	
	$rman_script +="#Backup DB" +$CLF 
	$rman_script +="SQL `"alter system checkpoint`"; "+$CLF
	$rman_script +="backup incremental LEVEL $inc_level tag `"DB_LEVEL_"+ $inc_level + "_DAY_" +$day_of_week+ "`" " +$compression+ " " +$sectionsize+ " DATABASE;" +$CLF 
	$rman_script +=$CLF 
    
	if ($db.db_backup_use_flash.equals("true")) {
		$rman_script +="CONFIGURE CHANNEL DEVICE TYPE DISK clear;" + $CLF 
	}	
	else{
		$check_path   = $dB.archive_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\backupset\%U"
		$rman_script +="CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '"+$check_path+"';" + $CLF 
		$check_path   = $dB.archive_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\autobackup\%F"
		$rman_script +="CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK to '" + $check_path + "';" +$CLF
	}

	$rman_script +="#Backup archivelogs "						+$CLF 
	$rman_script +="SQL `"alter system archive log current`";"	+$CLF 
	$rman_script +="backup "+ $compression + " archivelog ALL tag `"ARCHIVE_DAY$day_of_week`" DELETE INPUT;"	+$CLF 
	$rman_script +=""											+$CLF 


	$rman_script +="#Delete old Backups"						+$CLF 
	$rman_script +="delete noprompt obsolete;"				+$CLF 
	$rman_script +=""											+$CLF 

	$rman_script +="#Backup controlfile and spfile "			+$CLF 

	if ($db.db_backup_use_flash.equals("true")) {
		$rman_script +="CONFIGURE CHANNEL DEVICE TYPE DISK clear;"                               +$CLF 
		$rman_script +="CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK clear;"     +$CLF 
	}
	else {
		$check_path= $dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\backupset\%U"
		$rman_script +="CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '"+$check_path+"';" + $CLF 
		$check_path= $dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\autobackup\%F"
		$rman_script +="CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK to '"+$check_path+"';" + $CLF 
	}

	$rman_script +="backup current controlfile tag `"CONTROLFILE_DAY_" +$day_of_week+ "`";" + $CLF 
	$rman_script +="backup spfile tag `"SPFILE_DAY_"+$day_of_week+"`";"	+ $CLF 
	$rman_script +=$CLF 
	$rman_script +="#Summary info" + $CLF 
	$rman_script +="list backup summary;" + $CLF 
	$rman_script +=$CLF 
	
	# save the generated rman script to disk
	Set-Content -Path "$scriptpath\generated\generated_rman.rman" -value $rman_script
	
	#start the backup script for this day
	local-print  -Text "Info -- Start RMAN to start DB Backup"
	& $ORACLE_HOME/bin/rman target "$rman_connect_string" nocatalog "@$scriptpath\generated\generated_rman.rman" 2>&1 | foreach-object { local-print -text "RMAN OUT::",$_.ToString() }

	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	local-print  -Text "Info -- Finish Backup DB Files of DB::" ,$DB.dbname ,"at::", $endtime, " - Duration::", $duration, "Minutes"  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Finish Backup DB Files of DB::" ,$DB.dbname ,"at::", $endtime, " - Duration::", $duration, "Minutes"
	
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
	#
	# The meta data backup is moved to runDBMetaBackup.sh
	#
	# Save new backupsets to disk
	# use only if asm is archive and rman backup destination
	if ($db.backup_flash_to_disk.equals("true")) {
		$starttime=get-date
		$check_path= $dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()
		local-print  -Text "Info -- Start Flash Recovery Backup of the Backup Files of DB::", $DB.dbname, "at::" , $starttime, " to:" ,$check_path  -ForegroundColor "yellow"
		local-log-event -logText "Info -- Start Flash Recovery Backup of the Backup Files of DB::", $DB.dbname, "at::" , $starttime, " to:" ,$check_path
		
		$rman_script  ="# copy only new backups"+ $CLF 
		$rman_script +="CONFIGURE BACKUP OPTIMIZATION ON;"+ $CLF 
		$rman_script +="#copy backup from +asm to file location"+ $CLF 
		$rman_script +="backup backupset all format '"+$check_path+"\rman_%U';"+ $CLF 
		$rman_script +="#Backup controlfile and spfile"+ $CLF 
		$rman_script +="backup current controlfile tag `"controlfile_backup_disk`" format '"+$check_path+"\control_%U';"+ $CLF 
		$rman_script +="backup spfile tag `"spfile_backup_disk`" format '"+$check_path+"\spfile_%U';"+ $CLF 
		$rman_script +="CONFIGURE BACKUP OPTIMIZATION OFF;"+ $CLF 
		# save the file
		Set-Content -Path "$scriptpath\generated\generated_backup_flash.rman" -value $rman_script
		#
		# Start RMAN to store the content of the flash_recovery_area to a local disk 
		local-print  -Text "Info -- Start RMAN to export Flash Recovery Area to Disk"
		& $ORACLE_HOME/bin/rman target "$rman_connect_string" nocatalog "@$scriptpath\generated\generated_backup_flash.rman" 2>&1 | foreach-object { local-print -text "RMAN OUT::",$_.ToString() }
		#
		$endtime=get-date
		$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
		local-print  -Text "Info -- Finish Flash Recovery Backup of the Backup Files of DB::", $DB.dbname ,"at::",  $duration, "Minutes"  -ForegroundColor "yellow"
		local-log-event -logText "Info -- Finish Flash Recovery Backup of the Backup Files of DB::", $DB.dbname ,"at::",  $duration, "Minutes"
		local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
	}	
}

#==============================================================================
function local-backup-db-metainfo {
	Param ( 	$db 
			, 	$sql_connect_string  = "/ as sysdba"
	) #end param
	
	$starttime=get-date
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
	local-print  -Text "Info -- Start Backup Metadata of DB::", $DB.dbname, "at::", $starttime, "for day of the week::", $day_of_week  -ForegroundColor "yellow"
	local-log-event -logText  "Info -- Start Backup Metadata of DB::", $DB.dbname, "at::", $starttime, "for day of the week::", $day_of_week
	
	
	$ORACLE_HOME=$dB.oracle_home.ToString()
	$ORACLE_SID=$dB.sid.ToString()
		
	# Check if the backup directories exits
	local-check-all-directories($DB)
	
	$backup_path=$dB.db_backup_dest.ToString()+"\"+$dB.dbname.ToString()
	$dbname=$dB.dbname.ToString()
	$spfile_backup=$backup_path + "\init"+$dbname+"_"+$day_of_week+".ora"
	$controlfile_backup=$backup_path+"\controlfile_trace"+$day_of_week+".trc"
	
	# Save init.ora
	# Save controlfile

	$sql_script ="ALTER DATABASE backup controlfile TO trace AS '"+$controlfile_backup+"' reuse;" + $CLF
	$sql_script+="CREATE pfile='"+$spfile_backup+"' FROM spfile;"+ $CLF
	$sql_script+="exit;"+ $CLF
	
	# save the file
	Set-Content -Path "$scriptpath\generated\generated_create_control_spfile.sql" -value $sql_script
	
	# Call the script 
	local-print  -Text "Info -- Start SQL*Plus to create TXT trace of control and TXT init.ora from spfile"

	# if using / as sysdba avoid the duplicate as sysdba
	$sql_connect_string_sysdba=""
	if ($sql_connect_string.IndexOf("sysdba") -gt 0) {
		$sql_connect_string_sysdba=$sql_connect_string
	}
	else {
		$sql_connect_string_sysdba=$sql_connect_string+" as sysdba"
	}
	
	& "$ORACLE_HOME/bin/sqlplus" -s "$sql_connect_string_sysdba" "@$scriptpath\generated\generated_create_control_spfile.sql" 2>&1 | foreach-object { local-print -text "SQLPLUS OUT::",$_.ToString() }

	#PatchLevel of the database
	$software_inventory_backup=$backup_path+"\software_lsinventory_"+$dbname+"_"+$day_of_week+".log"
	## if Error with no set Oracle Home check this code!
	& cmd /c "set ORACLE_HOME=$ORACLE_HOME&&$ORACLE_HOME/OPatch/opatch lsinventory > $software_inventory_backup"
   
	#Save Password File
	$pwd_backup=$backup_path+"\PWD"+$ORACLE_SID+"_"+$DAY_OF_WEEK+".ora"
	cp "$ORACLE_HOME\database\PWD$ORACLE_SID.ora" "$pwd_backup"
		
	# Run Script to get DB Metadata Information
	# Read configuration
	
	$use_dot_net=$false
	$dot_net_library=""

	# use sqlplus or .net dll
	if ( $db.db_meta_info.HasAttribute("use_dot_net") ){
	    if ( $db.db_meta_info.GetAttribute("use_dot_net").equals("true") ) {					
			$dot_net_library=$db.db_meta_info.GetAttribute("dot_net_orcle_home")
			#search for the library in the path of dot_net_orcle_home
			try {
				$fl=Get-ChildItem $dot_net_library -Recurse -Include "Oracle.DataAccess.dll" -ErrorAction silentlycontinue
				if ($fl) {
					if ($fl.count) {
						$dot_net_library=$fl[0].DirectoryName +"\"+ $fl[0].Name
					} 
					else {
						$dot_net_library=$fl.DirectoryName +"\"+ $fl.Name
					}
				}		
				# Use .net!
				if (get-item $dot_net_library -ErrorAction silentlycontinue ) {
					$use_dot_net=$true	
				}
				else {
					$use_dot_net=$false	
					$i=$error.count-1
					local-print  -ErrorText "Error --",$error[$i]
				}
			} 
			catch {
				local-print  -ErrorText "Error -- Dot Net Library Oracle.DataAccess.dll not found in path (attribute dot_net_orcle_home) ::",$dot_net_library
				$use_dot_net=$false
			}			
		}	
		else {
			local-print  -ErrorText "Info -- use sqlplus to get DB meta information" 
			$use_dot_net=$false
		}		
	}
	else {
		local-print  -ErrorText "Error -- attribute use_dot_net of xml node db_meta_info not there"
		$use_dot_net=$false		
	}	
	
	# Check if tns alias usage is configured
	if ($db.nls_settings.use_direct_connnect_for_sys.equals("true")){
		local-print  -ErrorText "Error -- need sys user over tnsalias connection to use .net feature"
		$use_dot_net=$false	
	}	
	
	# start using dot_net
	if ( $use_dot_net) {
		
		$metainfo_backup=$backup_path+"\db_meta_information_"+$dbname+"_"+$day_of_week+".csv"
		
		# recrate File
		$sep=";"
		$csv="sep="+$sep+$CLF
		set-Content -Path "$metainfo_backup" -value $csv
		
		# Load the dll
		$handle=db_load_dll -dll_path $dot_net_library
		$handle=$handle[1]
		
		#connect to the DB
		# get user name und tns
		$ltns_alias = $db.nls_settings.tns_alias.toString()
		$lepassword = ($db.nls_settings.username).GetAttribute("password") 
		$lepassword = local-read-secureString -text $lepassword
		$lusername  = $db.nls_settings.username.InnerText
		
		$connect=db_connect -user $lusername -password $lepassword -tns_alias $ltns_alias -OracleConnection $handle
		
		##########
	
		# read from the DB
		[String[]]$csv_header ="----- Version -----"+$CLR
		[String[]]$sql        ="select * from v`$version"
		#
		$csv_header	+="----- DB Options -----"+$CLR
		$sql       	+="select * from v`$option"
		#
		$csv_header	+="----- patchlevel -----"+$CLR
		$sql	    +="select * from sys.registry`$history"
		#
		$csv_header	+="----- properties  -----"+$CLR
		$sql       	+="select property_name,property_value from database_properties"
		#
		$csv_header	+="----- charset  -----"+$CLR
		$sql       	+="select * from nls_database_parameters"
		#
		$csv_header	+="----- dbid  -----"+$CLR
		$sql       	+="select name,dbid from v`$database"
		#
		$csv_header	+="----- datastructur db files ------"+$CLR
		$sql       	+="select name as datafile_name from v`$datafile"
		#
		$csv_header	+="----- datastructur tempfiles ------"+$CLR
		$sql       	+="select name as tempfile_name from v`$tempfile"
		#
		$csv_header	+="----- datastructur log files ------"+$CLR
		$sql       	+="select member as logfile_name from v`$logfile"
		#
		$csv_header	+="----- datastructur tablespace ------"+$CLR
		$sql       	+="select tablespace_name,block_size from dba_tablespaces order by tablespace_name"
		#
		$csv_header	+="----- archive  -----"+$CLR
		#archive log list Fix to sql!
		$sql       	+="select * from v`$logfile"
		#		
		$csv_header	+="----- flashback -----"
		$sql       	+="select flashback_on,log_mode from v`$database"

		for ($i=0 ; $i -lt $csv_header.count; $i++) {
			
			local-print  -Text "Info -- read from DB::",$csv_header[$i]
			local-print  -Text "Info -- with::",$sql[$i]
			
			try {
				db_read_sql -SQLCommand $sql[$i] -OracleConnection  $handle -result_file $metainfo_backup -headerinfo $csv_header[$i]
				#write-host $i + " -->" + $csv_header[$i]+ " => " + $sql[$i]
			}
			catch {
				local-print  -ErrorText "Error -- read from DB::",$csv_header[$i],"with::",$sql[$i],"error::",$_
			}
		}
					
		#
		#
		$csv_header=""
		$sql=""
		#
		db_close_connect -OracleConnection  $handle
	
	}
	else {
		# use sqlplus
		$metainfo_backup=$backup_path+"\db_meta_information_"+$dbname+"_"+$day_of_week+".log"
		local-print  -Text "Info -- write the meta information as SQL*Plus Spool of DB into::",$metainfo_backup
		& $ORACLE_HOME/bin/sqlplus "$sql_connect_string" "@$scriptpath\sql\info.sql" "$metainfo_backup"  | out-null
	}
	
	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	local-print  -Text "Info -- Finish Backup Metadata of DB::", $DB.dbname ,"at::" ,$endtime ," - Duration::" , $duration,  "Minutes"  -ForegroundColor "yellow"
	local-log-event -logText   "Info -- Finish Backup Metadata of DB::", $DB.dbname ,"at::" ,$endtime ," - Duration::" , $duration,  "Minutes" 
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
}

#==============================================================================
# backup only the archive of at database
#
###	

function local-backup-db-archive {
	Param (   $db 
			, $sql_connect_string  = "/ as sysdba"
			, $rman_connect_string = "/" 
	) #end param
	
	$starttime=get-date
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
	
	local-print  -Text "Info -- Start Backup Archivelogs of DB::", $DB.dbname, "at::", $starttime  -ForegroundColor "yellow"
	local-log-event -logText  "Info -- Start Backup Archivelogs of DB::", $DB.dbname, "at::", $starttime
	$ORACLE_HOME=$dB.oracle_home.ToString()
	$ORACLE_SID=$dB.sid.ToString()
	
	# Check if the backup directories exits
	local-check-all-directories($DB)
	
	##check Version of Database
	# Must be on the first line!!
	# fix if user is sys ...
$isenterprise=@'
set pagesize 0 
set feedback off
select count(*) from v$version where banner like '%Enterprise%';
quit
'@| & "$ORACLE_HOME/bin/sqlplus" -s "$sql_connect_string"
	
	try {
		$isenterprise=$isenterprise.Trim()
	}
	catch {
		local-print  -ErrorText "Error - Connection Problem::" ,$isenterprise
	}

	local-print  -Text "Info -- check DB Version - Get 1 for EE and 0 for SE - Result is ::" ,$isenterprise

	# Optimize the backup for Enterprise features
	#
	$compression=""
		
	if ($isenterprise -eq 1) {
		#PARALLELISM
		$parallelism=$dB.db_backup_channels.toString();
		$parallelism="PARALLELISM "+$parallelism
	}
	

	if ($db.archive_use_flash.equals("true")) {
		$rman_script +="CONFIGURE CHANNEL DEVICE TYPE DISK clear;"                               +$CLF 
		$rman_script +="CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK clear;"     +$CLF 
	}
	else {
		$check_path= $dB.archive_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\backupset\%U"
		$rman_script +="CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '"+$check_path+"';" + $CLF 
		$check_path= $dB.archive_backup_dest.ToString()+"\"+$dB.dbname.ToString()+"\autobackup\%F"
		$rman_script +="CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK to '"+$check_path+"';" + $CLF 
	}

	$rman_script +="#Backup archivelogs " +$CLF 
	$rman_script +="SQL `"alter system archive log current`";" +$CLF 
	$rman_tag="ARCHIVE_DAY_"+$day_of_week
	$rman_script +="backup "+ $compression + " archivelog ALL tag `""+ $rman_tag +"`" DELETE INPUT;" +$CLF 
	$rman_script +=""+$CLF 
	$rman_script +="#Backup controlfile and spfile " +$CLF 
	$rman_tag="CONTROLFILE_DAY_" +$day_of_week
	$rman_script +="backup current controlfile tag `"" + $rman_tag + "`";" + $CLF 
	$rman_tag="SPFILE_DAY_"+$day_of_week
	$rman_script +="backup spfile tag `""+$rman_tag+"`";" + $CLF 
	$rman_script +=$CLF 
	$rman_script +="#Summary info" + $CLF 
	$rman_script +="list backup summary;" + $CLF 
	$rman_script +=$CLF 
	
	# save the generated rman script to disk
	Set-Content -Path "$scriptpath\generated\generated_archive.rman" -value $rman_script
	
	#start the backup script for this day
	& $ORACLE_HOME/bin/rman target "$rman_connect_string" nocatalog "@$scriptpath\generated\generated_archive.rman" 2>&1 | foreach-object { local-print -text "RMAN OUT::",$_.ToString() }
	
	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	local-print  -Text "Info -- Finish Backup Archivelogs of DB::" ,$DB.dbname ,"at::", $endtime, " - Duration::"  ,$duration  ,"Minutes"  -ForegroundColor "yellow"
	local-log-event -logText  "Info -- Finish Backup Archivelogs of DB::" ,$DB.dbname ,"at::", $endtime, " - Duration::"  ,$duration  ,"Minutes"
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
}

#==============================================================================
# Export the users from the DB with datapump
#
###
function local-backup-db-user {
	Param ( 	$db
			, 	$sql_connect_string  = "/ as sysdba"
	) #end param
	
	$starttime=get-date
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
		
	$ORACLE_HOME=$dB.oracle_home.ToString()
	$ORACLE_SID=$dB.sid.ToString()
	$dbname=$dB.dbname.ToString()
	
	# start the export job for each user
	foreach ($exportuser in $db.db_user_export.user.username) {
		
		$db_user=($exportuser).InnerText.ToUpper().trim()
		local-print     -Text    "Info -- Start Export User::",$db_user,"of DB::" ,$dbname ,"at::" ,$starttime -ForegroundColor "yellow"
		local-log-event -logText "Info -- Start Export User::",$db_user,"of DB::" ,$dbname ,"at::" ,$starttime
		
		# check if the user exists and can connect
		$test_script=$CLF
		$test_script+="set pagesize 0"+$CLF
		$test_script+="set feedback off"+$CLF
		$test_script+="select count(*) from all_users where upper(username) like '"+$db_user+"';"+$CLF
		$test_script+="quit"+$CLF
		
		# check if the user exists
		$user_exists = $test_script | & "$ORACLE_HOME/bin/sqlplus" -s "$sql_connect_string"
		$user_exists=$user_exists.Trim()
		local-print  -Text "Info -- check if User exists - Result is ::" ,$user_exists
		if ($user_exists.equals("0")){
			local-print     -Text    "Error -- Export User::",$db_user,"not possible - user not exits"   -ForegroundColor "red"
			local-log-event -logText "Error -- Export User::",$db_user,"not possible - user not exits"   -logtype "Error"			
		}
		else {
	
			# check Export Directory
			$export_db_dir=$dB.db_user_export.export_dir_db.ToString()
			$export_os_dir=$dB.db_user_export.export_dir_os.ToString() + "\" + $dbname
			
			local-print -Text "Info -- check the export Directory DB::", $export_db_dir, "OS Directory::", $export_os_dir
			
			# check the path in the fileystem
			local-check-dir -lcheck_path $export_os_dir -dir_name "DB EXPORT"
			
			# Check if directory exists and check location , if wrong create and/or fix directory	
			$sql_script ="set serveroutput on"+ $CLF
			$sql_script+="declare" + $CLF
			$sql_script+="v_dir        dba_directories.DIRECTORY_PATH%type; " + $CLF
			$sql_script+="v_count      pls_integer;" + $CLF
			$sql_script+="v_dirname    varchar2(2000):='$export_os_dir';" + $CLF
			$sql_script+="v_export_dir varchar2(2000):=upper('$export_db_dir');" + $CLF
			$sql_script+="v_username   varchar2(2000):=upper('$db_user');" + $CLF
			$sql_script+="begin" + $CLF
			$sql_script+=" dbms_output.put_line('check for directory '||v_export_dir);" + $CLF
			$sql_script+=" select count(*) into v_count from dba_directories where DIRECTORY_NAME=v_export_dir;" + $CLF
			$sql_script+=" if v_count > 0 then" + $CLF
			$sql_script+="	select DIRECTORY_PATH into v_dir from dba_directories where DIRECTORY_NAME=v_export_dir;" + $CLF
			$sql_script+="	dbms_output.put_line('directory '||v_export_dir||' exists for OS directory::'||nvl(v_dir,'-'));" + $CLF
			$sql_script+="	if v_dir not like v_dirname then" + $CLF
			$sql_script+="		dbms_output.put_line('relink directory '||v_export_dir||' to OS directory::'||v_dirname);" + $CLF
			$sql_script+="		execute immediate 'drop directory '||v_export_dir||'';" + $CLF
			$sql_script+="		execute immediate 'create directory '||v_export_dir||' as '''||v_dirname||'''';" + $CLF
			$sql_script+="	end if;" + $CLF
			$sql_script+=" else" + $CLF
			$sql_script+="	dbms_output.put_line('create directory '||v_export_dir||' for OS directory::'||nvl(v_dirname,'-'));" + $CLF
			$sql_script+="	execute immediate 'create directory '||v_export_dir||' as '''||v_dirname||'''';" + $CLF
			$sql_script+=" end if;" + $CLF
			$sql_script+=" execute immediate 'grant all on directory '||v_export_dir||' to '||v_username;" + $CLF
			$sql_script+="end;" + $CLF
			$sql_script+="/ " + $CLF
			$sql_script+="exit;"+ $CLF
			
			# save the file
			Set-Content -Path "$scriptpath\generated\generated_check_export_dir.sql" -value $sql_script
			
			# Call the script 
			local-print  -Text "Info -- Start SQL*Plus to check the export directory"
			& "$ORACLE_HOME/bin/sqlplus" -s "$sql_connect_string" "@$scriptpath\generated\generated_check_export_dir.sql" 2>&1 | foreach-object { local-print -text "SQLPLUS OUT::",$_.ToString() }
			
			#which user should do the export, if attribute use_sys_account is true use / as sysdba
			$connect_string="'$sql_connect_string'"
			if ( ($exportuser).HasAttribute("use_sys_account")){
				#
				if ( ($exportuser).GetAttribute("use_sys_account").equals("true") ) {
					# use the local sys account with the / syntax, only possible if os user is in ora_dba group 
					# and NTS propertie is set in sqlnet.ora
					if ($sql_connect_string.equals("/ as sysdba")){
						$connect_string="'$sql_connect_string'"
					}
					else {
						$connect_string="$sql_connect_string"
					}
					
					local-print  -Text "Info -- Start Export with the backup user account see parameter section nls_settings in config file."
					$user_can_connect=local-check-connect -sql_connect_string $sql_connect_string
				} 
				else{
					# get the password for the connection
					$epassword=($exportuser).GetAttribute("password") 
					$epassword=local-read-secureString -text $epassword
					
					$tns_alias=""
					if ( ($exportuser).HasAttribute("tns_alias")){
						$tns_alias=($exportuser).GetAttribute("tns_alias") 
					}
					
					$connect_string=$db_user+"/"+$epassword+"@"+$tns_alias
					$log_connect_string=$db_user+"/*******"+"@"+$tns_alias
					
					local-print  -Text "Info -- Start Export with the connect string::", $log_connect_string
					
					$user_can_connect=local-check-connect -sql_connect_string $connect_string
							
				}
			}
			else {
				local-print  -Text "Error -- attribute use_sys_account on username is missing." -  -ForegroundColor "red"		 
				$connect_string="$sql_connect_string"
			}			
			# check if the user can connect
			
			
			#
			$inc_level="0"
			# read export Policy
			$export_policy=$dB.db_user_export.export_policy.toString();
			local-print  -Text "Info -- Read Export Policy",$export_policy
			#
			try {
				$apolicy=$export_policy.Split(",")
				#
				if ( $apolicy.Length -eq 7 ) {
					$inc_level=$apolicy[$day_of_week-1]
					local-print  -Text "Info -- Set Export Policy for day of week",$day_of_week ,"to" , $inc_level
				}
				else {
					local-print  -Text "Error -- Export Policy is not correct! Using the default Policy - Export Policy::" ,$export_policy -ForegroundColor "red"
					# hold the last two export on disk, and hold one export for one week
					switch ($day_of_week) {
						1 {$inc_level="0" }
						2 {$inc_level="1" }
						3 {$inc_level="0" }
						4 {$inc_level="1" }
						5 {$inc_level="0"}
						6 {$inc_level="1"}
						7 {$inc_level="2"}
						default 
						  {$inc_level="1"}
					} 
				}
			}
			catch {
				$inc_level="0"
				local-print  -Text "Error -- Export Policy is not correct! Fix the error - Error::" ,$_ -ForegroundColor "red"
			}			
			
			# create the parameter file for datapump
			$dp_script ="DIRECTORY="+$export_db_dir+$CLF
			$dp_script+="DUMPFILE="+$db_user+"_"+$inc_level+"_%U.dmp"+$CLF
			$dp_script+="JOB_NAME="+$db_user+"_"+$day_of_week+"_JOB"+$CLF
			$dp_script+="REUSE_DUMPFILES=Y"+$CLF
			$dp_script+="SCHEMAS="+$db_user+$CLF
			$dp_script+="LOGFILE=EXPORT_"+$db_user+"_"+$inc_level+".log"+$CLF
			# 10GB Filesize each part
			$dp_script+="FILESIZE="+(1024*1024*1024*10)+$CLF
			
			# save the generated rman script to disk
			Set-Content -Path "$scriptpath\generated\generated_export.dp" -value $dp_script
						
			#start the export of the data
			if ( $user_can_connect -eq "true" ) {	
				& "$ORACLE_HOME/bin/expdp" "$connect_string" "parfile=$scriptpath\generated\generated_export.dp" 2>&1 | foreach-object { local-print -text "EXPDP OUT::",$_.ToString().replace($CLF," ") }
				
				# zip the result 
				$compress_export=$dB.db_user_export.compress_export.ToString()
				if ($compress_export.equals("true"))  {
					$ziplib_path="$scriptpath\lib\zip\ICSharpCode.SharpZipLib.dll"
					local-print  -Text "Info -- try to load zip lib for compression the export from::",$ziplib_path
					try {
						# see
						# source for ziplib : http://powershellzip.codeplex.com/				
						# examples  http://devio.wordpress.com/2009/02/11/zipping-files-with-powershell/
						# 
						
						[System.Reflection.Assembly]::LoadFrom($ziplib_path) 
						$zip = New-Object ICSharpCode.SharpZipLib.Zip.FastZip 
						
						$zip_name=$export_os_dir+"\"+$db_user+"_"+$inc_level+".zip"
						
						local-print  -Text "Info -- Create zip File ::",$zip_name," in Export dir::",$export_os_dir
						
						$zip.CreateZip($zip_name,$export_os_dir,$false,"\.dmp$")
						
						#Remove the old dumps after the zip
						# * must be on the end of the path variable!!
						$export_os_dir+="\*"
						Remove-Item -path $export_os_dir -include *.DMP
					}
					catch {
						local-print     -Text    "Error -- Compessing Export not succesfull reason::",$_   -ForegroundColor "red"
					}
				}
				else {
					local-print  -Text "Info -- Export not compressed"
				}
			}
			else {
				local-print     -Text    "Error -- Export User::",$db_user,"not possible - user can not connect"   -ForegroundColor "red"
				local-log-event -logText "Error -- Export User::",$db_user,"not possible - user can not connect"   -logtype "Error"			
			}			
		}
	}
	
	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	local-print  -Text "Info -- Finish Export User Job of DB::", $DB.dbname ,"at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Finish Export User Job of DB::", $DB.dbname ,"at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
}

#==============================================================================
# backup the metadata of the asm enviroment
##
function local-backup-asm-metainfo {
Param ( $asm )

	$starttime=get-date
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
	

	$ORACLE_HOME = $asm.asm_oracle_home.ToString()
	$ORACLE_SID  = $asm.asm_instancesid.ToString()
		
		
	$backup_path=$asm.asm_backup_dest.ToString()+"\"+$asm.asm_instancesid.ToString()
	# Check if the backup directories exits
	local-check-dir -lcheck_path $backup_path -dir_name "ASM Meta Infos"
	
	$dbname=$asm.asm_instancesid.ToString()
	$spfile_backup=$backup_path + "\init"+$dbname+"_"+$day_of_week+".ora"
	$controlfile_backup=$backup_path+"\controlfile_trace"+$day_of_week+".trc"
	
	
	# Save init.ora
	$sql_script ="CREATE pfile='"+$spfile_backup+"' FROM spfile;"+ $CLF
	$sql_script+="exit;"+ $CLF
	
	# save the file
	Set-Content -Path "$scriptpath\generated\generated_create_control_spfile_asm.sql" -value $sql_script
	
	# Call the script 
	local-print  -Text "Info -- Start SQL*Plus to create TXT init.ora from spfile"

	& "$ORACLE_HOME/bin/sqlplus" -s "/ as sysdba" "@$scriptpath\generated\generated_create_control_spfile_asm.sql" 2>&1 | foreach-object { local-print -text "SQLPLUS OUT::",$_.ToString() }
	
	
	#PatchLevel of the database
	$software_inventory_backup=$backup_path+"\software_lsinventory_"+$dbname+"_"+$day_of_week+".log"
	## if Error with no set Oracle Home check this code!
	& cmd /c "set ORACLE_HOME=$ORACLE_HOME&&$ORACLE_HOME/OPatch/opatch lsinventory > $software_inventory_backup"
   
	#Save Password File
	$pwd_backup=$backup_path+"\PWD"+$ORACLE_SID+"_"+$DAY_OF_WEEK+".ora"
	cp "$ORACLE_HOME\database\PWD$ORACLE_SID.ora" "$pwd_backup"
	
	
	#Save Disk and Directroy Configuration
	#
	$disk_config_backup=$backup_path+"\asm_configuration_disk_conf_"+$ORACLE_SID+"_"+$DAY_OF_WEEK+".trc"
	
	if (get-item  $disk_config_backup -ErrorAction silentlycontinue ) {
		rm  $disk_config_backup
	}
	
	try {
		& "$ORACLE_HOME\bin\asmcmd.bat" md_backup -b $disk_config_backup 2>&1 | foreach-object { local-print -text "ASMCMD OUT::",$_.ToString() }
	}
	catch {
		local-print -errorText "Error -- Failed to get ASM Disk Config with asmcmd :: The error was: $_."	 	
	}
	
	# Fix
	# store the disk configuration of this node in a text file
	#
	
	
	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	local-print  -Text "Info -- Finish Backup of ASM Meta information at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Finish Backup of ASM Meta information at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
}

#==============================================================================
# backup the metadata of the grid enviroment
##
function local-backup-grid-metainfo {
Param ( $grid )
	local-print  -Text "Info -- not yet fully tested and implemented"
	
	$starttime=get-date
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
	
    # Get Oracle Home
	$ORACLE_HOME = $grid.grid_oracle_home.ToString()

	# get the cluster name
	$clustername=@( & "$ORACLE_HOME\bin\cemutlo" -n)
	
	# the backup path
	$backup_path=$grid.grid_backup_dest.ToString()+"\"+$clustername
	
	# Check if the backup directories exits
	local-check-dir -lcheck_path $backup_path -dir_name "Grid Meta Infos"
	
	#PatchLevel of the database
	$software_inventory_backup=$backup_path+"\software_lsinventory_grid_"+$day_of_week+".log"
	## if Error with no set Oracle Home check this code!
	& cmd /c "set ORACLE_HOME=$ORACLE_HOME&&$ORACLE_HOME/OPatch/opatch lsinventory > $software_inventory_backup"
	
	#Save ocr
	local-print  -Text "Info -- Make a backup of the ocr and Voting Disk"
	& "$ORACLE_HOME\bin\ocrconfig" -manualbackup 2>&1 | foreach-object { local-print -text "OCR OUT::",$_.ToString() }
	
	#Save the ocr backup of the local node
	local-print  -Text "Warning -- !!! in this version only the local ocr backup will be saved !!!" -ForegroundColor "yellow"
	
	$hostname=@( hostname )
	local-check-dir -lcheck_path "$backup_path\$hostname" -dir_name "Grid Note OCR Files"
	cp "$ORACLE_HOME\cdata\$cluster_name\*.ocr"  "$backup_path\$hostname" 2>&1 | foreach-object { local-print -text "copy OUT::",$_.ToString() }
	
	
	<#  Bash version ---------------------------------------------
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
			sudo scp -p root@${NODE}:${ORACLE_HOME}/cdata/${CLUSTER_NAME}/*.ocr  ${BACKUP_DEST}/${CLUSTER_NAME}/${NODE}
		done
		#Save Backup of Voting Disk not longer necessary in 11g 
	#>
	
	#Save OCR Regitry Infos
	$ocr_info_file=$backup_path+"\ocr_"+$clustername+"_"+$day_of_week+".dump"
	$ocr_info=@()
	try {
	    # no logging local-print -text "OCRDUMP OUT::",$_.ToString();
		& "$ORACLE_HOME\bin\ocrdump" -stdout 2>&1 | foreach-object {  $ocr_info+=$_.ToString() }
		set-content $ocr_info_file $ocr_info
	}
	catch {
		local-print -errorText "Error -- Failed to get ASM Disk Config with asmcmd :: The error was: $_."	 	
	}

	#Where is the voting Disk?
	$vot_info_file=$backup_path+"\vot_"+$clustername+"_"+$day_of_week+".log"
	$vot_info=@()	
	try {
	    # no logging local-print -text "CRSCTL OUT::",$_.ToString();
		& "$ORACLE_HOME\bin\crsctl" query css votedisk 2>&1 | foreach-object { $vot_info+=$_.ToString() }
		set-content $vot_info_file $vot_info
	}
	catch {
		local-print -errorText "Error -- Failed to get GRID Disk Config with asmcmd :: The error was: $_."	 	
	}


	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	
	local-print  -Text "Info -- Finish Backup of GRID Meta information at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Finish Backup of GRID Meta information at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
}


#==============================================================================
# Wrapper to call robocopy
##

function backupFiles {
param ( $files )
	
	$starttime=get-date
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
	
	local-print     -Text     "Info -- Start Backup Files","at::" ,$starttime -ForegroundColor "yellow"
	local-log-event -logText  "Info -- Start Backup Files","at::" ,$starttime
	
	foreach ($pair in $files.pair) {
		$soure_directory=$pair.source_dir.toString().trim();
		$target_directory=$pair.target_dir.toString().trim();
		$roptions=$pair.robocopy_parameter.InnerText
		rcopydata -soure_directories  $soure_directory -target_directory $target_directory -roptions $roptions
	
	}	
	
	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	
	local-print  -Text "Info -- Finish Backup Files::",      "at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Finish Backup Files::","at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"
	
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
}

#==============================================================================
# local-check-db-alertlog
# check the alert log of the database
##
function local-check-db-alertlog{

param (   $db 
		, $sql_connect_string)
		

	local-print  -Text "Info -- Check Alert.log"
	
	$starttime=get-date
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
	
	## check the alert log		
	
	# check if adrci is accessible
		# if yes use adrci
		# get all incident information with adrci
	##
	
	
	# if not geht the alert_log position
	# get parameter bdump from sqlplus
$alert_log=@'
set pagesize 0 
set feedback off
select value from v$parameter where name ='background_dump_dest';
quit
'@| & "$ORACLE_HOME/bin/sqlplus" -s "$sql_connect_string"
		
		local-print  -Text "Info -- read the alert log destination from the database::",$alert_log
		
		try {
			
			$alert_log=$alert_log.trim()
				
			# check if size << 500MB => if bigger warning => 1GB error!
			$alert_log_file=(get-ChildItem "$alert_log\alert_$env:ORACLE_SID.log")  #| out-null
						
			$alert_log_size=($alert_log_file.length/1MB)
			
		     
			if ( $alert_log_size -gt  1000 ) {
				local-print  -ErrorText ("Error -- Alertlog of the instance::{0} -> size::{1:n} MB to big!" -f $env:ORACLE_SID,$alert_log_size)
			}
			elseif ( $alert_log_size -gt  500 ) {
				local-print  -Text ("Warning -- Alertlog of the instance::{0} -> size ::{1:n} MB" -f $env:ORACLE_SID,$alert_log_size)  -ForegroundColor "yellow"
			}
			else {
				local-print  -Text ("Info -- Alertlog of the instance::{0} -> size::{1:n} MB" -f $env:ORACLE_SID,$alert_log_size)
			}
		
	 
			# make copy with the ocopy utilty
			$alert_check_log = "$alert_log\alert_$env:ORACLE_SID.check_log"
			$alert_log_full_name=$alert_log_file.toString()

			local-print  -Text "Info -- Copy the open file ::",$alert_log_full_name, " to::" , $alert_check_log
		
			#copy
			& "$env:ORACLE_home\bin\ocopy"  "$alert_log_full_name" "$alert_check_log" 2>&1 | foreach-object { local-print -text "OCOPY OUT::",$_.ToString() }
					
			# read the last byte position from conf.file
			$log_status_xml="$scriptpath\conf\last_config_status.xml"
			if (get-ChildItem $log_status_xml -ErrorAction silentlycontinue ) {
				#read 
				$log_last_status= [xml] ( get-content $log_status_xml)				
			}
			else {	
				$log_last_status= [xml] "<alert_log><last_byte_position>0</last_byte_position></alert_log>"
			}
			#
			$byte_pos=$log_last_status.alert_log.last_byte_position.toString()
					
			# check the file 
			# return the byte position of the last read in this file
			$byte_pos=local-get-file_from_position -filename $alert_check_log -byte_pos $byte_pos -search_pattern (local-get-oracle-error-pattern) -log_file (local-get-statusfile) -print_lines_after_match 5
		    						
			$log_last_status.alert_log.last_byte_position="$byte_pos"
			# save the status file again on disk 
			$log_last_status.save($log_status_xml)
		
		} 
		catch {
			local-print -ErrorText "Error--",$_
			throw "Error check the alert.log :: $_"
		}
	##	

	
	##
	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	
	local-print  -Text "Info -- Finish Check Alert Logs::",      "at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Finish Check Alert Logs::","at::" ,$endtime ," - Duration::"  ,$duration , "Minutes"
	
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
	
 }


#============================= End of File ====================================



