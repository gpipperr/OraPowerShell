#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   generic Backup Script to use VSS to backup open files
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

#===================generic Backup Script to use VSS to backup open files =====
# see http://msdn.microsoft.com/en-us/library/aa384589(v=vs.85)
#==============================================================================
<#

  Security:
  (see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
  To switch it off (as administrator)
  get-Executionpolicy -list
  set-ExecutionPolicy -scope CurrentUser RemoteSigned
  
	.NOTES
		Created: 08.2012 : Gunther Pippèrr (c) http://www.pipperr.de				
	.SYNOPSIS
		Generic Backup Script for the VSS Backup
	.DESCRIPTION
		Backup create a snapshot for a volume , copy the data , drop the snapshot
	
	.COMPONENT
		Oracle Backup Script
	.EXAMPLE
		Backup the Database
		.\runVSSBackup.ps1
		
#>

#==============================================================================
# Enviroment
#==============================================================================

# Path

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

write-host "Info -- start the Script in the path $scriptpath"  -ForegroundColor "green"	

cd  $scriptpath

# Script path
$scriptpath=get-location
$config_xml="$scriptpath\conf\backup_file_config.xml"

# read Helper Functions
.  $scriptpath\lib\backuplib.ps1

#==============================================================================
# move old logfile to .0 
# if log is older then today, if not append
# we have per day one logfile from this week and from the last week the .0 logs

$starttime=get-date
# Numeric Day of the week
$day_of_week=[int]$starttime.DayofWeek 

$logfile_name=$scriptpath.path+"\log\VSSFILE_BACKUP_"+$day_of_week+".log"
	
write-host "Info -- Use Logfile Name :: $logfile_name"  -ForegroundColor "green"	

# Log
local-clear-logfile -log_file $logfile_name

################ Semaphore Handling ########################################### 
# Only one script can run at one time

# create named Semaphore
# http://msdn.microsoft.com/de-de/library/kt3k0k2h
# Only on script can run at one time, 1 Resouce possilbe from 1 with the Name ORALCE_BACKUP
$sem = New-Object System.Threading.Semaphore(1, 1, "VSS_BACKUP")

#==============================================================================

# read Configuration
$backupconfig= [xml] ( get-content $config_xml)

#==============================================================================

local-print  -Text "Info -- Check if other instance of a Backup script is running (over Semaphore VSS_BACKUP)"
# Wait till the semaphore if free
$sem.WaitOne() | out-null

#==============================================================================
		
$starttime=get-date
# Numeric Day of the week
$day_of_week=[int]$starttime.DayofWeek 

#############
#Prepare the backup
##
function prepareBackup {
		Param (
			  $meta_data_cab_file   = "c:\vss_meta_oracle_data.cab"
			, $volume_alias         = "OracleData"
			, $volume_drive_letter  = "D:"
			, $vss_vol_drive_letter = "X:"
		)
# BEGIN Section
Begin { }
# Main
Process {

		local-print         -Text "Info -- Start VSS Backup::", "at::", $starttime  -ForegroundColor "yellow"
		local-log-event -logText  "Info -- Start VSS Backup::", $DB.dbname, "at::", $starttime

		local-print  -Text "Info -- prepare the script vss_generated_prepare.vss to prepare the VSS Copy of the drive"	
		# generate the diskshadow command file
		$vss_script="SET CONTEXT PERSISTENT"+$CLF
		$vss_script+="SET METADATA "+$meta_data_cab_file+""+$CLF
		#$vss_script+="SET VERBOSE ON"+$CLF
		# start Backup Modus
		$vss_script+="BEGIN BACKUP"+$CLF
		#Alias for the volumen
		$vss_script+="ADD VOLUME "+$volume_drive_letter+" ALIAS "+$volume_alias+""+$CLF  
		#Create Snapshot
		$vss_script+="CREATE"+$CLF
		#VSS Copy als drive
		$vss_script+="EXPOSE %"+$volume_alias+"% "+$vss_vol_drive_letter+""+$CLF
		$vss_script+="LIST shadows all"+$CLF
		
		# save the generated script to disk
		Set-Content -Path "$scriptpath\generated\vss_generated_prepare.vss" -value $vss_script
		# create  copy
		& 	"$env:SystemRoot\system32\diskshadow.exe" -s "$scriptpath\generated\vss_generated_prepare.vss"  2>&1 | foreach-object { local-print -text "VSS OUT::",$_.ToString() }
	}
End {}
}

#==============================================================================
#Do the backuo
##
function doBackup{
		param (
			 [String]   $vss_vol_drive_letter = "X:"
			,[String[]] $soure_directories
			,[String]   $target_directory
			,[String]   $roptions
		)
	local-print  -Text "Info -- try to start the backup of the files from $vss_vol_drive_letter"
	
	# start the copy process
	rcopydata -soure_directories $soure_directories -target_directory $target_directory -options $roptions
		
	local-print  -Text "Info -- finish backup of the files from $vss_vol_drive_letter"
}

#==============================================================================
#end the backup
##
function endBackup {
		param (
			 $vss_vol_drive_letter = "X:"
			,$volume_drive_letter  = "D:"
		)
	
	local-print  -Text "Info -- prepare the script vss_generated_finish.vss to finish the backup"	
	# generate the diskshadow command file
	$vss_script="END BACKUP"+$CLF
	$vss_script+="LIST shadows all"+$CLF
	$vss_script+="DELETE SHADOWS  EXPOSED "+$vss_vol_drive_letter+""+$CLF
	$vss_script+="LIST shadows all"+$CLF

	# save the generated script to disk
	Set-Content -Path "$scriptpath\generated\vss_generated_finish.vss" -value $vss_script
    # start the script
    & 	"$env:SystemRoot\system32\diskshadow.exe" -s "$scriptpath\generated\vss_generated_finish.vss"  2>&1 | foreach-object { local-print -text "VSS OUT::",$_.ToString() }
	
	# check if for this volume a other snapshot exits
	#http://msdn.microsoft.com/en-us/library/windows/desktop/aa389391(v=vs.85).aspx
	#$class=[WMICLASS]"root\cimv2:win32_shadowcopy"
	#$shadowVolume = get-wmiobject Win32_ShadowVolumeSupport 
	#http://msdn.microsoft.com/en-us/library/aa389391(v=VS.85).aspx
	
	$shadow = get-wmiobject win32_shadowcopy
	
	if ($shadow) {
		local-print  -Text "Error -- there are still shadow copies on the system count::",$shadow.count -ForegroundColor "red"			
		foreach ($s in $shadow) {
			local-print  -Text "Error -- ID        ::",$s.id
			local-print  -Text "Error -- VolumeName::",$s.VolumeName
		}
		#http://technet.microsoft.com/de-de/library/cc754915(v=ws.10).aspx
		$vss_script="delete shadows volume "+$volume_drive_letter+""+$CLF		
		# save the generated script to disk
		Set-Content -Path "$scriptpath\generated\vss_generated_clean.vss" -value $vss_script
		# start the script
		local-print  -Text "Error -- delete all copy for volumen::",$volume_drive_letter -ForegroundColor "red"	
		& 	"$env:SystemRoot\system32\diskshadow.exe" -s "$scriptpath\generated\vss_generated_clean.vss"  2>&1 | foreach-object { local-print -text "VSS OUT::",$_.ToString() }
	}
	else {
		local-print  -Text "Info -- All shadow copies are cleaned"
	}

	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	local-print  -Text "Info -- Finish VSS Backup::"        ,"at::", $endtime, " - Duration::"  ,$duration  ,"Minutes"  -ForegroundColor "yellow"
	local-log-event -logText  "Info -- Finish VSS Backup::" ,"at::", $endtime, " - Duration::"  ,$duration  ,"Minutes"
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
}

################  start ##################


############################### start Backup ##########################################
try{

	#Parameter
	$meta_data_cab_file  	="c:\vss_meta_oracle_data.cab"

	foreach ( $volume in $backupconfig.backup.volume ) {

		$volume_alias 			=$volume.name
		$volume_drive_letter	=$volume.driveletter
		$vss_vol_drive_letter 	=$volume.vss_driveletter
				
		local-print -Text "Info -- Start VSS Backup  for::",$volume_alias," driver Letter ::",$volume_drive_letter
		
		prepareBackup 	-meta_data_cab_file  $meta_data_cab_file -volume_alias $volume_alias -volume_drive_letter $volume_drive_letter -vss_vol_drive_letter $vss_vol_drive_letter
			
		foreach ( $folder in $volume.folder ) {
			
			# Source folder
			$source=$folder.source.toString()
			# set the path informatation to the VSS drive
			$source=$source.replace($volume_drive_letter,$vss_vol_drive_letter)
			
			# target
			$target=$folder.target.toString()
			
			
			local-print -Text "Info -- Copy from VSS::",$source," to ::",$target
			
			# Options for the robocopy prozess
			$roptions=$folder.robocopy_parameter.toString()
			
			# start the backup 
			doBackup 		-vss_vol_drive_letter $vss_vol_drive_letter -soure_directories $source  -target_directory $target -roptions $roptions
		}
	 	endBackup 		-vss_vol_drive_letter $vss_vol_drive_letter -volume_drive_letter $volume_drive_letter
	}
	
} 
catch {
	local-print -Text "Error -- Failed to create backup: The error was: $_."	 -ForegroundColor "red"			
	local-log-event -logtype "Error" -logText "Error -- Failed to create backup: The error was: $_."				
}
finally {
		###############################################################################
		# Exit the semaphore
		local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
		local-print  -Text "Info -- relase the Semaphore VSS_BACKUP"
		try {
			$sem.Release() |  out-null
		}
		catch {
			local-print -Text "Error -- Faild to relase the emaphore VSS_BACKUP - not set or Backup not started?"	-ForegroundColor "red"			
		}
		local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
		###############################################################################
}


