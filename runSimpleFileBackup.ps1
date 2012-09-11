#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   generic Backup Script for file backups
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================
<#

  Security:
  (see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
  To switch it off (as administrator)
  get-Executionpolicy -list
  set-ExecutionPolicy -scope CurrentUser RemoteSigned
  
	.NOTES
		Created: 09.2012 : Gunther Pippèrr (c) http://www.pipperr.de
	.SYNOPSIS
		Generic Backup Script for File Backup
	.DESCRIPTION
		Backup / copy the data
	
	.COMPONENT
		Oracle Backup Script
	.EXAMPLE
		Backup the Database
		.\runVSSBackup.ps1
		
#>


#==============================================================================
# Enviroment

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

write-host "Info -- start the Script in the path $scriptpath"  -ForegroundColor "green"

cd  $scriptpath

# Script path
$scriptpath=get-location
$config_xml="$scriptpath\conf\backup_file_config.xml"

# read Helper Functions
.  $scriptpath\lib\backuplib.ps1
# load monitoring library
. $scriptpath\lib\monitoring.ps1

###############################################################################
# log and status file handling
#
# move old logfile to .0 
# if log is older then today, if not append
# we have per day one logfile from this week and from the last week the .0 logs

$starttime=get-date
# Numeric Day of the week
$day_of_week=[int]$starttime.DayofWeek 

# Log
# set the global logfile
$logfile_name=$scriptpath.path+"\log\FILE_BACKUP_"+$day_of_week+".log"
local-set-logfile    -logfile  $logfile_name
local-clear-logfile  -log_file $logfile_name

# Status Mail
$logstatusfile_name=$scriptpath.path+"\log\STATUS.txt"
local-set-statusfile -statusfile $logstatusfile_name
local-clear-logfile  -log_file $logstatusfile_name


################ Semaphore Handling ########################################### 
# Only one script can run at one time

# create named Semaphore
# http://msdn.microsoft.com/de-de/library/kt3k0k2h
# Only on script can run at one time, 1 Resouce possilbe from 1 with the Name ORALCE_BACKUP
$sem = New-Object System.Threading.Semaphore(1, 1, "FILE_BACKUP")

###############################################################################


#==============================================================================

# read Configuration
$backupconfig= [xml] ( get-content $config_xml)

#==============================================================================

$starttime=get-date
# Numeric Day of the week
$day_of_week=[int]$starttime.DayofWeek 

#==============================================================================
#Prepare the backup
##
function prepareBackup {
	# BEGIN Section
Begin {
		
		local-print  -Text "Info -- Check if other instance of a Backup script is running (over Semaphore FILE_BACKUP)"
		# Wait till the semaphore if free
		$sem.WaitOne() | out-null
	}
# Main
Process {

		local-print        -Text "Info -- Start File Backup::", "at::", $starttime  -ForegroundColor "yellow"
		local-log-event -logText "Info -- Start File Backup::", "at::", $starttime		
	}
End {}
}

#==============================================================================
#Do the backuo
##
function doBackup{
		param (
			 [String]   $vol_drive_letter = "D:"
			,[String[]] $soure_directories
			,[String]   $target_directory
			,[String]   $roptions
		)
	local-print  -Text "Info -- try to start the backup of the files from $vol_drive_letter"
	
	# start the copy process
	rcopydata -soure_directories $soure_directories -target_directory $target_directory -roptions $roptions
	
	local-print  -Text "Info -- finish backup of the files from $vol_drive_letter"
}

#==============================================================================
#end the backup
##
function endBackup {
			
	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	local-print  -Text "Info -- Finish File Backup::"        ,"at::", $endtime, " - Duration::"  ,$duration  ,"Minutes"  -ForegroundColor "yellow"
	local-log-event -logText  "Info -- Finish File Backup::" ,"at::", $endtime, " - Duration::"  ,$duration  ,"Minutes"
	local-freeSpace 
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
}

################  start ##################


############################### start Backup ##########################################
try{

    
	prepareBackup

	foreach ( $volume in $backupconfig.backup.volume ) {

		
		if ( $volume.use_vss.equals("true") ) {
			local-print -Text "Warning -- to copy with Volumen Shadow Copy use Script runVSSBackup!"	-ForegroundColor "yellow"			
		}
		
		$vol_name			=$volume.name
		$vol_drive_letter 	=$volume.driveletter.toString()
		local-print -Text "Info -- Start Backup  for::",$vol_name," driver Letter ::",$vol_drive_letter
	
		foreach ( $folder in $volume.folder ) {
			
			$source=$folder.source.toString()
			$target=$folder.target.toString()
			
			
			
			# connect the share
			$target_share=$folder.target_share.toString()
			local-print -Text "Info -- Connect to Share ::",$target_share
			
			& net use $target_share 2>&1 | foreach-object { local-print -text "NET USE OUT::",$_.ToString() }
			
			local-print -Text "Info -- Copy::",$source," to ::",$target
			
			# Options for the robocopy prozess
			$roptions=$folder.robocopy_parameter.InnerText
			
			# Do the Backup
			doBackup 	-vol_drive_letter $vol_drive_letter -soure_directories $source  -target_directory $target -roptions $roptions
		}
	}
	#
	endBackup 

} 
catch {
	local-print -Text "Error -- Failed to create backup: The error was: $_."	 -ForegroundColor "red"			
	local-log-event -logtype "Error" -logText "Error -- Failed to create backup: The error was: $_."				
}
finally {
			#==============================================================================
			# Exit the semaphore
			local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
			local-print  -Text "Info -- relase the Semaphore FILE_BACKUP"
			try {
				$sem.Release() |  out-null
			}
			catch {
				local-print -Text "Error -- Faild to relase the emaphore FILE_BACKUP - not set or Backup not started?"	-ForegroundColor "red"			
			}
			local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
			#==============================================================================
			
			#==============================================================================
			# Check the logfiles and create summary text for check mail
			
			local-get-file_from_postion -filename (local-get-logfile) -byte_pos 0 -search_pattern "error","fehler","0x0000" -log_file (local-get-statusfile)
			
			#==============================================================================
}


