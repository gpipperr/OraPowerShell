#==============================================================================
# Author: Gunther Pipp�rr ( http://www.pipperr.de )
# Desc:    Oracle generic Backup Script
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

<#

  
	.NOTES
		Created: 08.2012 : Gunther Pipp�rr (c) http://www.pipperr.de

		Security:
		(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
		To switch it off (as administrator)
		get-Executionpolicy -list
		set-ExecutionPolicy -scope CurrentUser RemoteSigned
  
	.SYNOPSIS
		Generic Backup Script for the Oracle Database 
		
	.DESCRIPTION
		Backup script read backup_config.xml and execute a full backup of the databae
		
	.PARAMETER argumet 1
		DB backups the DB / Archivelogs / Metadata/ Export the user
		ARCHIVE backup only the archivelogs ( if you like to backup for example every hour the archivelog to a other destination) 
		
	.COMPONENT
		Oracle Backup Script
		
	.EXAMPLE
		Backup the Database
		.\runBackup.ps1 DB
		Backup only the archivelogs
		.\runBackup.ps1 ARCHIVE

#>

# Environment
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
	throw "Configuration xml file version info missing, please check the xml template from the  new version and add the version attribute to <backup> !"
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
# .Net Helper
.  $scriptpath\lib\oracle_dotnet_connect.ps1

################ Semaphore Handling ########################################### 
# Only one script can run at one time

# create named Semaphore
# http://msdn.microsoft.com/de-de/library/kt3k0k2h
# Only on script can run at one time, 1 Resouce possilbe from 1 with the Name ORACLE_BACKUP
$sem = New-Object System.Threading.Semaphore(1, 1, "ORACLE_BACKUP")


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
$logfile_name=$scriptpath.path+"\log\DB_BACKUP_"+$day_of_week+".log"
local-set-logfile    -logfile $logfile_name
local-clear-logfile -log_file $logfile_name

# Status Log file
$logstatusfile_name=$scriptpath.path+"\log\STATUS.txt"
local-set-statusfile -statusfile $logstatusfile_name
local-clear-logfile  -log_file  (local-get-statusfile)

#==============================================================================
# Check for unencrypted passwords
local-print  -Text "Info -- Check for unencrypted passwords"

# encrypt the password and change the xml config
$result=local-encryptXMLPassword $backupconfig

# Store Configuration (needed if password was not encrypted!)
if ($result.equals(1)) { 
    local-print  -Text "Info -- Save XML Configuration with encrypted password"
	$backupconfig.Save("$config_xml")
}
else {
	local-print  -Text "Info -- XML Backup Configuration not changed - all passwords encrypted"
}

# check for password in the mail_xml

# encrypt the password and change the xml configuration
$result=local-encryptXMLPassword $mailconfig

# Store Configuration (needed if password was not encrypted!)
if ($result.equals(1)) { 
    local-print  -Text "Info -- Save XML Configuration with encrypted password"
	$mailconfig.Save("$mailconfig_xml")
}
else {
	local-print  -Text "Info -- XML Configuration for E-mail Transport not changed - all passwords encrypted"
}

#
#==============================================================================

################## Backup the Database ########################################

#==============================================================================
# start the Backup
# Parameter: [DB|ARCHIVE]
# DB 		=> Backup Database
# ARCHIVE 	=> Backup only the Archives of the DB
# 
##
function startBackup {
Param ( 
		[String] $scope = "DB"
)
# BEGIN Section
Begin {
	
	local-print  -Text "Info -- Check if other instance of a backup script is running (over Semaphore ORACLE_BACKUP)"
	# Wait till the semaphore if free
	$wait_on_semaphore=$sem.WaitOne()

}

# Main
Process {
	
	#ASM
	foreach ($asm in $backupconfig.backup.asm) {
		if ($asm.asm_in_use.Equals("true")) {
			if ($asm.asm_meta_info.Equals("true")) {
				local-print  -Text "Info -- start backup configuration of the ASM instance"
				
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
					
				local-backup-asm-metainfo -asm $asm
			}
		}		
	}
	
	#GRID
	foreach ($grid in $backupconfig.backup.grid) {
		if ($grid.grid_in_use.Equals("true")) {
			if ($grid.backup_grid.Equals("true")) {
				
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

				local-print  -Text "Info -- start backup configuration of the GRID instance"
				
				local-backup-grid-metainfo -grid $grid
			}
		}
	}

	# Database 
	foreach ($db in $backupconfig.backup.db) {
		
		# the the DB enviroment
		local-set-dbEnviroment -db $db 
		
		# create the connect string to the database
		$sql_connect_string ="/ as sysdba"
		$rman_connect_string="/"

		if ($db.nls_settings.use_direct_connnect_for_sys.equals("true")){
			$sql_connect_string="/ as sysdba"
			$rman_connect_string="/"
			local-print  -Text "Info -- use as connection to the database::",$sql_connect_string
		}
		else {
			$tns_alias = $db.nls_settings.tns_alias.toString()
			$epassword = ($db.nls_settings.username).GetAttribute("password") 
			$epassword = local-read-secureString -text $epassword
			$username  = $db.nls_settings.username.InnerText
			$sql_connect_string   =  $username+"/"+$epassword+"@"+$tns_alias
			$log_connection_string = $username+"/***********"+"@"+$tns_alias
			$rman_connect_string = $sql_connect_string
			local-print  -Text "Info -- use as connection to the database::",$log_connection_string
		}

		# Check if the connect is possible
		$can_connect=local-check-connect -sql_connect_string $sql_connect_string
		
		if ($scope.equals("DB")) {
			local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
			try {
				#Only if the connect to the DB is possible
				if ($can_connect.equals("true")) {
					
					# Backup the database
					if ($db.db_backup.Equals("true")) {
						local-backup-database -db $db -sql_connect_string $sql_connect_string -rman_connect_string $rman_connect_string
					} 
					
					# get the meta information like controlfile trace
					if ($db.db_meta_info.InnerText.Equals("true")) {
						local-backup-db-metainfo -db $db -sql_connect_string $sql_connect_string
					} 
					
					# check alert Log
					if ($db.db_check_alert_log.InnerText.Equals("true")) {
						
						# how many line you like to see after a match in the alertlog
						$print_lines_after_match=1
						$use_adrci=$false
						
						# check if configured over the config xml
						if ( $db.db_check_alert_log.HasAttribute("print_lines_after_match")){
							$print_lines_after_match=$db.db_check_alert_log.GetAttribute("print_lines_after_match")
						}
						
						# Use adrci to analyse the log?
						if ( $db.db_check_alert_log.HasAttribute("use_adrci")){
							if ("true".equals($db.db_check_alert_log.GetAttribute("use_adrci"))) {
								$use_adrci=$true
							}
						}
						# start the analyse
						local-check-db-alertlog -db $db -sql_connect_string $sql_connect_string -print_lines_after_match $print_lines_after_match -use_adrci $use_adrci
					} 
					
					# User export
					if ($db.db_user_export.export.Equals("true")) {
						local-backup-db-user  -db $db -sql_connect_string $sql_connect_string
					} 
					
				}
			} 
			catch {
				throw "Error -- Failed to create backup: The error was: $_."
			}
		}
		
		if ($scope.equals("ARCHIVE")) {
			local-print  -Text "Info ------------------------------------------------------------------------------------------------------"

			try {
				if ($can_connect.equals("true")) {
					
					if ($db.db_archive.Equals("true")) {
						local-backup-db-archive -db $db -sql_connect_string $sql_connect_string -rman_connect_string $rman_connect_string
					}
					else {
						local-print -Text "Error-- Archive Log backup was not enabled (db_archive=false) for this instance::",$ORACLE_SID   -ForegroundColor "red"
					}
				}
			} 
			catch {
					local-print -Text "Error-- Failed to create Archive Log backup: The error was: $_."	 -ForegroundColor "red"
					local-log-event -logtype "Error" -logText "Error- -- Failed to create Archive Log backup: The error was: $_."
			}
		}
	}
	# Copy generated files
	if ($backupconfig.backup.files.copyfiles.Equals("true")) {
		
		local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
		
		try {
			backupFiles -files $backupconfig.backup.files 
		}
		catch{
			throw "Error- -- Failed to create backup: The error was: $_."
		}
	}
}

#END
End { }

} ## end startBackup

############################### start Backup ##########################################
try{
   
    $argument1 = $args[0]
	
	if ($argument1) {
		$argument1 = $argument1.toUpper()
		if ( $argument1.equals("DB") -or  $argument1.equals("ARCHIVE") ) {
			local-print -Text "Info -- Backup Script started with Parameter::",$argument1
		}
		else {
			local-print -Text "Error -- Backup Script wrong Parameter::",$argument1  -ForegroundColor "red"
			local-print -Text "Error -- Valid Parameter for the Database is:: DB"  -ForegroundColor "red"
			local-print -Text "Error -- Valid Parameter for the archive log of the Database is:: ARCHIVE"  -ForegroundColor "red"
			exit
		}
	}
	else {
		# if no parameter backup the complete DB environment
		$argument1='DB'
		local-print -Text "Warning -- Backup Script called without parameter" -ForegroundColor "Yellow"
		local-print -Text "Info -- Backup Script started with default parameter::",$argument1
	}

	startBackup -scope $argument1

	local-freeSpace 

} 
catch {
	#  Error Details:
	#  $error[0].Exception | fl * -force
	#
	local-print -Text "Error -- Failed to create backup: The error was: $_." -ForegroundColor "red"
	local-log-event -logtype "Error" -logText "Error- -- Failed to create backup: The error was: $_."
}
finally {

			#==============================================================================
			# Exit the semaphore
			local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
			local-print  -Text "Info -- release  the Semaphore ORALCE_BACKUP"
			try {
				$sem.Release() |  out-null
			}
			catch {
				local-print -Text "Error -- Failed to release  the semaphore ORALCE_BACKUP - not set or Backup not started?" -ForegroundColor "red"
			}
			local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
			#==============================================================================

			#==============================================================================
			# Check the log files and create summary text for check mail
			
			$last_byte_pos=local-get-file_from_position -filename (local-get-logfile) -byte_pos 0 -search_pattern (local-get-error-pattern -list "oracle") -log_file (local-get-statusfile)
			# send the result of the check to a mail recipient 
			# only if configured!
			local-send-status -mailconfig $mailconfig -log_file (local-get-statusfile)
			
			#==============================================================================

}

#============================= End of File ====================================







