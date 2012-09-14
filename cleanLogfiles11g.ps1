#==============================================================================
# Author: Gunther Pipp�rr ( http://www.pipperr.de )
# Desc:   Oracle Rotate Logfile Script for Oracle 11g
# Date:   September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================
<#
	.NOTES
		Created: 09.2012 : Gunther Pipp�rr (c) http://www.pipperr.de

		Security:
		(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
		To switch it off (as administrator)
		get-Executionpolicy -list
		set-ExecutionPolicy -scope CurrentUser RemoteSigned
  
	.SYNOPSIS
		Script to rotate the alert log and purge ADR contents
		
	.DESCRIPTION
		Script to rotate the alert log and purge ADR contents
		
	.PARAMETER  Log_retention
		Purge Alert/Listener log (plain text format). Default: <5> days
	.PARAMETER Short_retention
		Purge TRACE, CDUMP, UTSCDMP and IPS. Default: <30> days
	.PARAMETER Long_retention
		Purge ALERT, INCIDENT, SWEEP, STAGE and HM. Default: <365> days
	
	.COMPONENT
		Oracle Backup Script
	
	.EXAMPLE

#>

#==============================================================================

# Enviroment
Set-Variable CONFIG_VERSION "0.2" -option constant

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

write-host "Info -- start the Script in the path $scriptpath"  -ForegroundColor "green"	

cd  $scriptpath

# Script path
# FIX?
$scriptpath=get-location

#==============================================================================

$config_xml="$scriptpath\conf\backup_config.xml"

# read Configuration
$backupconfig= [xml] ( get-content $config_xml)

#Check if the XML file has the correct version
if ( $backupconfig.backup.HasAttribute("version") ) {
	$xml_script_version=$backupconfig.backup.getAttribute("version")
	if ( $CONFIG_VERSION.equals( $xml_script_version)) {
		write-host "Info -- XML configuration with the right version::  $CONFIG_VERSION "
	}
	else {
		throw "Configuration xml file version is wrong, found: $xml_script_version but need :: $CONFIG_VERSION !"
	}
 }
else {
	throw "Configuration xml file version info missing, please check the xml template from the  new version and add the version attribte to <backup> !"
}

# read if exist the mail configuration
$mailconfig_xml="$scriptpath\conf\mail_config.xml"

if (Get-ChildItem $mailconfig_xml -ErrorAction silentlycontinue) {
	$mailconfig = [xml]  ( get-content $mailconfig_xml)
}
else {
	$mailconfig = [xml] "<mail><use_mail>false</use_mail></mail>"
}

#==============================================================================
# read Helper Functions
.  $scriptpath\lib\backuplib.ps1

# load monitoring library
. $scriptpath\lib\monitoring.ps1

# Oracle Backup main scripts
.  $scriptpath\lib\oraclebackuplib.ps1

#==============================================================================


################ Semaphore Handling ########################################### 
# Only one script can run at one time

# create named Semaphore
# http://msdn.microsoft.com/de-de/library/kt3k0k2h
# Only on script can run at one time, 1 Resouce possilbe from 1 with the Name ORALCE_BACKUP
$sem = New-Object System.Threading.Semaphore(1, 1, "ORACLE_LOG_ROTATE")

#==============================================================================
# log and status file handling
#
# move old log file to .0 
# if log is older then today, if not append
# we have per day one log file from this week and from the last week the .0 logs

$starttime=get-date
# Numeric Day of the week
$day_of_week=[int]$starttime.DayofWeek 


# Default log files for each day of the week
$logfile_name=$scriptpath.path+"\log\DB_LOG_ROTATE_"+$day_of_week+".log"
local-set-logfile    -logfile $logfile_name
local-clear-logfile -log_file $logfile_name

# Status Log file
$logstatusfile_name=$scriptpath.path+"\log\STATUS.txt"
local-set-statusfile -statusfile $logstatusfile_name
local-clear-logfile  -log_file  (local-get-statusfile)

#==============================================================================
function local-cleanDBLog {
	param (
		  $db
		, $sql_connect_string
		, $Short_retention = 30
		, $Long_retention  = 365
	)
	
	local-print -Text "Info -- Cleaning the logfile of the database", $env:ORACLE_SID
	
	# get the ADR Home
	
	$adr_base=@'
set pagesize 0 
set feedback off
SELECT value FROM v$diag_info WHERE NAME = 'ADR Base';
quit
'@| & "$env:ORACLE_HOME\bin\sqlplus" -s "$sql_connect_string"
	
	$adr_home_path=@'
set pagesize 0 
set feedback off
SELECT replace(homepath.value,adrbase.value||'\','') FROM v$diag_info homepath, v$diag_info adrbase WHERE homepath.name = 'ADR Home'  AND adrbase.name  = 'ADR Base';
quit
'@| & "$env:ORACLE_HOME\bin\sqlplus" -s "$sql_connect_string"

	local-print -Text "Info -- ADR Base::",$adr_base, " Home path of this DB::", $env:ORACLE_SID, "Path::",$adr_home_path

	# set the ADR BASE
	try {
		set-item -path env:ADR_BASE -value $adr_base
	}
	catch {
		new-item -path env: -name ADR_BASE -value $adr_base
	}
	local-print  -Text "Info -- set ADR_BASE to::" , $env:ADR_BASE
	
	# call adrci
	$hrs_short=24*60*$Short_retention
	$hrs_long =24*60*$Long_retention
	$adr_home_path=$adr_home_path.replace("\","\\")
	
	local-print -Text "Info -- start adrci with set homepath $adr_home_path;set control (SHORTP_POLICY=$hrs_short) ;set control (LONGP_POLICY=$hrs_long);purge "
	
	& "$env:ORACLE_HOME\bin\adrci" exec="set homepath $adr_home_path;set control \(SHORTP_POLICY=$hrs_short\); set control \(LONGP_POLICY=$hrs_long\);purge" 2>&1 | foreach-object { local-print -text "ADRCI OUT::",$_.ToString() }
	
	#done

	# audit_file_dest clean the audit files
	
	$audit_file_dest=@'
set pagesize 0 
set feedback off
select value from v$parameter where name='audit_file_dest';
quit
'@| & "$env:ORACLE_HOME\bin\sqlplus" -s "$sql_connect_string"

	# Clean the adump of the DB
	$today = get-date 
	
	local-print -Text ("Info -- Cleaning the audit log files of the database older then 30 days from now {0:D} from location {1}" -f $today,$audit_file_dest)
	
	# using $Short_retention for the audits!
	get-childitem $audit_file_dest -recurse | where-object {($today - $_.LastWriteTime).Days -gt $Short_retention}  | remove-item
	

}

#==============================================================================
# clean the listner log
#
##
function local-cleanListenerLog {
	param (
		 $log_rentention
	)
	
	local-print -Text "Info -- Cleaning the Listner logfile not yet fully implemented"
	
	
	if (-not (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
		local-print -Text "Info -- Cleaning the Listner logfile you need administrative rights!"
		#local-print -Text "Info -- Try to start a  administrative session"
		#Start-Process powershell -Verb runAs -ArgumentList "lsnrctl show log_file"
	}
	else {
		
		$listener_home=@()
		# collect the results of the lsnrctl 
		& "$env:ORACLE_HOME\bin\lsnrctl" show oracle_home 2>&1 | foreach-object { $listener_home+=$_.ToString() }
		foreach ($s in $listener_home) {
			if  ( $s.indexOF("ORACLE_HOME=") -gt -1 ) {
				$listener_home= $s.Split("=")[1]
				$listener_home= $listener_home.replace('"','')
			}
		}
		local-print -Text "Info -- Listener runs under this ORACLE_HOME:",$listener_home
		try {
			set-item -path env:ORACLE_HOME -value $listener_home
		}
		catch {
			new-item -path env: -name ORACLE_HOME -value $listener_home
		}	
		local-print  -Text "Info -- Set Oracle Home to::" , $env:ORACLE_HOME
		$xml_listener_log=@()
		& "$env:ORACLE_HOME\bin\lsnrctl" show log_file 2>&1 | foreach-object { $xml_listener_log+=$_.ToString() }
		foreach ($s in $xml_listener_log) {
			if  ( $s.indexOF("LISTENER Parameter") -gt -1 ) {
				$xml_listener_log= $s.Split(" ")[5]
				$xml_listener_log= $xml_listener_log.replace('"','')
			}
		}
			local-print  -Text "Info -- Listener logs to this logfile ::" , $xml_listener_log
		
	}
}

#==============================================================================
# clean the grid logs
#
##
function local-cleanGRIDLog {
	param (
		$grid_home
	)
	
	local-print -Text "Info -- Cleaning the Grid logfile not implemented"
}

#==============================================================================


#============================== Start the Log Rotate / Purge ==================
try{

	$log_rentention  = $args[0]
	$Short_retention = $args[1]
	$Long_retention  = $args[2]
	
	# set the defaults
	if ( -not $log_rentention   ) { $log_rentention   = 5   }
	if ( -not $short_retention  ) { $short_retention  = 30  }
	if ( -not $long_retention   ) { $long_retention   = 365 }
	
	
	$listner_home=""
		
	#ASM
	foreach ($asm in $backupconfig.backup.asm) {
		if ($asm.asm_in_use.Equals("true")) {
			#Oracle ASM SID
			$ORACLE_SID=$asm.asm_instancesid.ToString()
			try {
				set-item -path env:ORACLE_SID -value $ORACLE_SID
			}
			catch {
				new-item -path env: -name ORACLE_SID -value $ORACLE_SID
			}
			local-print  -Text "Info -- set Oracle SID to::" , $env:ORACLE_SID
						
			#ASM ORACLE_HOME
			$ORACLE_HOME=$asm.asm_oracle_home.ToString()
			if ("default".equals($ORACLE_HOME)){
				$ORACLE_HOME=local-get-crs-home-from-inventory
			}
			
			# check if the directory exits
			$check_result=local-check-dir -lcheck_path $ORACLE_HOME -dir_name "ORACLE_HOME" -create_dir "false"
			
			# if Oracle Home not exits - exit
			if ($check_result.equals("false")) {
					throw "ORACLE_HOME::$ORACLE_HOME not exits for ASM Instance::$ORACLE_SID"
			}
				
			try {
				set-item -path env:ORACLE_HOME -value $ORACLE_HOME
			}
			catch {
				new-item -path env: -name ORACLE_HOME -value $ORACLE_HOME
			}
			local-print  -Text "Info -- set Oracle Home to::" , $env:ORACLE_HOME
			
			# Clean ASM instance logs
			local-cleanDBLog -db $asm -Short_retention $Short_retention -Long_retention $Long_retention
			# clean the log files of ASM enviroment - not yet implemented for Windows
			local-cleanGRIDLog -grid_home $grid_home
		}
	}
	
	#GRID
	foreach ($grid in $backupconfig.backup.grid) {
		if ($grid.grid_in_use.Equals("true")) {
			#GRID ORACLE_HOME
			$ORACLE_HOME=$grid.grid_oracle_home.ToString()
			if ("default".equals($ORACLE_HOME)){
				$ORACLE_HOME=local-get-crs-home-from-inventory
			}
			
			# check if the directory exits
			$check_result=local-check-dir -lcheck_path $ORACLE_HOME -dir_name "ORACLE_HOME" -create_dir "false"
				
			# if Oracle Home not exits - exit
			if ($check_result.equals("false")) {
					throw "ORACLE_HOME::$ORACLE_HOME not extis for GRID"
			}

			try {
				set-item -path env:ORACLE_HOME -value $ORACLE_HOME
			}
			catch {
				new-item -path env: -name ORACLE_HOME -value $ORACLE_HOME
			}
			
			local-print  -Text "Info -- set Oracle Home to::" , $env:ORACLE_HOME

			# clean the log files of the grid - not yet implemented for Windows
			local-cleanGRIDLog -grid_home $grid_home
		}
	}

	# Database 
	foreach ($db in $backupconfig.backup.db) {
		# the the DB enviroment
		local-set-dbEnviroment -db $db 
		
		# create the connect string to the database
		$sql_connect_string ="/ as sysdba"
		
		if ($db.nls_settings.use_direct_connnect_for_sys.equals("true")){
			$sql_connect_string="/ as sysdba"
			local-print  -Text "Info -- use as connection to the database::",$sql_connect_string
		}
		else {
			$tns_alias = $db.nls_settings.tns_alias.toString()
			$epassword = ($db.nls_settings.username).GetAttribute("password") 
			$epassword = local-read-secureString -text $epassword
			$username  = $db.nls_settings.username.InnerText
			$sql_connect_string   =  $username+"/"+$epassword+"@"+$tns_alias
			$log_connection_string = $username+"/***********"+"@"+$tns_alias
			local-print  -Text "Info -- use as connection to the database::",$log_connection_string
		}

		# Check if the connect is possible
		$can_connect=local-check-connect -sql_connect_string $sql_connect_string
		
		# clean the log files for every DB in the script
		local-cleanDBLog -db $db -sql_connect_string $sql_connect_string  -Short_retention $Short_retention -Long_retention $Long_retention
	}
	
	# check with the settings of the last DB the home of the listener
	# Clean the listener Log
	local-cleanListenerLog -log_rentention $log_rentention

	local-freeSpace 
} 
catch {
	#  Error Details:
	#  $error[0].Exception | fl * -force
	#
	local-print -Text "Error -- Failed to clean the Logfiles: The error was: $_." -ForegroundColor "red"
	local-log-event -logtype "Error" -logText "Error- -- Failed to clean the Logfiles: The error was: $_."
}
finally {

		#==============================================================================
		# Exit the semaphore
		local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
		local-print  -Text "Info -- release  the Semaphore ORACLE_LOG_ROTATE"
		try {
			$sem.Release() |  out-null
		}
		catch {
			local-print -Text "Error -- Faild to release  the emaphore ORACLE_LOG_ROTATE - not set or Backup not started?" -ForegroundColor "red"
		}
		local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
		#==============================================================================

		#==============================================================================
		# Check the logfiles and create summary text for check mail
		
		local-get-file_from_position -filename (local-get-logfile) -byte_pos 0 -search_pattern "error,fehler" -log_file (local-get-statusfile)
		# send the result of the check to a mail reciptant 
		# only if configured!
		local-send-status -mailconfig $mailconfig -log_file (local-get-statusfile)
		
		#==============================================================================

}

#==============================================================================


