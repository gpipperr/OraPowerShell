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
Set-Variable CONFIG_VERSION "0.2" -option constant


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
# move old log file to .0 
# if log is older then today, if not append
# we have per day one log file from this week and from the last week the .0 logs

$starttime=get-date
# Numeric Day of the week
$day_of_week=[int]$starttime.DayofWeek 

# Log
# set the global log file
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
	throw "Configuration xml file version info missing, please check the xml template from the new version and add the version attribte to <backup> !"
}

# read if exist the mail configuration
$mailconfig_xml="$scriptpath\conf\mail_config.xml"

if (Get-ChildItem $mailconfig_xml -ErrorAction silentlycontinue) {
	$mailconfig = [xml]  ( get-content $mailconfig_xml)
}
else {
	$mailconfig = [xml] "<mail><use_mail>false</use_mail></mail>"
}
# check for password in the mail_xml

# encrypt the password and change the xml config
$result=local-encryptXMLPassword $mailconfig

# Store Configuration (needed if passwort was not encrypted!)
if ($result.equals(1)) { 
    local-print  -Text "Info -- Save XML Configuration with encrypted password"
	$mailconfig.Save("$mailconfig_xml")
}
else {
	local-print  -Text "Info -- XML Configuration for E-mail Transport not changed - all passwords encrypted"
}

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
		$wait_on_semaphore=$sem.WaitOne() | out-null
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
			local-print -Text "Warning -- to copy with Volumen Shadow Copy use Script runVSSBackup!" -ForegroundColor "yellow"
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
			doBackup  -vol_drive_letter $vol_drive_letter -soure_directories $source  -target_directory $target -roptions $roptions
		}
	}
	#
	endBackup 

} 
catch {
	local-print -Text "Error -- Failed to create backup: The error was: $_." -ForegroundColor "red"
	local-log-event -logtype "Error" -logText "Error -- Failed to create backup: The error was: $_."
}
finally {
			#==============================================================================
			# Exit the semaphore
			local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
			local-print  -Text "Info -- release  the Semaphore FILE_BACKUP"
			try {
				$sem.Release() |  out-null
			}
			catch {
				local-print -Text "Error -- Faild to release  the emaphore FILE_BACKUP - not set or Backup not started?" -ForegroundColor "red"
			}
			local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
			#==============================================================================
			
			#==============================================================================
			# Check the log files and create summary text for check mail

			$last_byte_pos=local-get-file_from_position -filename (local-get-logfile) -byte_pos 0 -search_pattern (local-get-error-pattern -list "other") -log_file (local-get-statusfile)

			# send the result of the check to a mail reciptant 
			# only if configured!
			local-send-status -mailconfig $mailconfig -log_file (local-get-statusfile)

			#==============================================================================
}

#============================= End of File ====================================

# SIG # Begin signature block
# MIIEAwYJKoZIhvcNAQcCoIID9DCCA/ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnmgMxNDZrbeR3t2pCzH19kzT
# 80SgggIdMIICGTCCAYagAwIBAgIQswsffWbgur5FbTmMnxtNqDAJBgUrDgMCHQUA
# MBwxGjAYBgNVBAMTEUxvY2FsIENlcnRpZmljYXRlMB4XDTEyMTAwODE2NDUwMloX
# DTM5MTIzMTIzNTk1OVowGjEYMBYGA1UEAxMPUG93ZXJTaGVsbCBVc2VyMIGfMA0G
# CSqGSIb3DQEBAQUAA4GNADCBiQKBgQC2QvNu1p/Q30P/1MyJAadom1kOQ5r+DSk/
# si6OX1MyZBw7KAo5VJkVFSJUWkGycVWhS5g/vi7GJUfN59nfBsa+BOL2qWbgdUXJ
# kb4QAIFhnjLL3o0vahnFUvNLggU7e2Lb7U1HnXJ162M27piidMneo8iLULFZqbix
# 6SNOFra8zwIDAQABo2YwZDATBgNVHSUEDDAKBggrBgEFBQcDAzBNBgNVHQEERjBE
# gBDVerYLw85OfcC2L05Gi3JRoR4wHDEaMBgGA1UEAxMRTG9jYWwgQ2VydGlmaWNh
# dGWCEN6vlJpqhmiXQJ+5DWLZODswCQYFKw4DAh0FAAOBgQAtqLl71Y/h9pdorhGx
# TaQ+wHgjkBJ7YrVxYphnzdO0rQU8hPVSQr0cH3YX0IpAc7IRsbf3GPPldnAAk+Cs
# qOZ2PZtLDULf/wNhQ37rjfmBNZoHFRzSdaaEb1goFiTjHs4M1JmS3ZA0Uo89lSnA
# fr8wpIA2Al0lRo3Cys1EH4p/qzGCAVAwggFMAgEBMDAwHDEaMBgGA1UEAxMRTG9j
# YWwgQ2VydGlmaWNhdGUCELMLH31m4Lq+RW05jJ8bTagwCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FFxYHGKRdPA8w3Fl7L93rFAEgQdHMA0GCSqGSIb3DQEBAQUABIGAYWCE/+fEDG5N
# IVa3DrSl7Nsh1hx+MsSgePWbjocJN7OQMJpwOVzP8QiamriUY2V3ZbhKnNUfWduD
# 4azEygMy/lCyP61DwOnnadlOc/8mKPSGhZqPW8Hnl/MD4FmDxPb8BJXIPE6V0IXV
# 5V31khUf7kQ8Hy/ZnIaQZaCMV5k7OwA=
# SIG # End signature block
