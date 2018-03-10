#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Backup APEX instance
# Date:   March 2012
# Site:   https://www.pipperr.de/dokuwiki/doku.php?id=prog:apex_export_source_code_and_git
#==============================================================================
<#
	.NOTES
		Created: 03.2018 : Gunther Pippèrr (c) http://www.pipperr.de

		Security:
		(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
		To switch it off (as administrator)
		get-Executionpolicy -list
		set-ExecutionPolicy -scope CurrentUser RemoteSigned
  
	.SYNOPSIS
		Script to Backup APEX instance
		
	.DESCRIPTION
		Script to rScript to Backup APEX instance
		
	.COMPONENT
		Oracle Backup Script
	
	.EXAMPLE

#>

#==============================================================================



#==============================================================================
# Helper Function to write log file and display message
##

function local-print{
	# Parameters
	Param( 
		  [String]   $ForegroundColor = 'White'
		, [String[]] $text 
		, [String[]] $errortext
		
	)
	# End param
	Begin {}
	Process {
		$backup_log = $log_file
		# Message for the log
		if ($errortext){
			$text=$errortext 
			$ForegroundColor = "red"
		}
		$log_message = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") +":: " +$text 
		try {
			write-host -ForegroundColor $ForegroundColor $text  
			 # check if the file is accessible
			 try{
				$log_message  | Out-File -FilePath "$backup_log" -Append
			 }
			 catch {
			    write-host -ForegroundColor "red" "Error -- Log file not accessible see text above"
			 }
		} 
		catch {
				throw "Error -- Failed to create log entry in: $backup_log. The error was: $_."
		}
	}
	
	End {}
}

# Environment

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

$log_file="C:\work\apex_backup.log"

local-print -text  "Info -- start the Script in the path $scriptpath" 

# Runtime Parameter

$apex_util_dir = "C:\oracle\apex\utilities\"
$ora_odbc_lib  = "C:\oracle\products\12.2.0.1\dbhome_1\jdbc\lib\ojdbc8.jar"
$java_home     = "C:\Program Files\Java\jdk1.8.0_112"
$git_home      = "C:\Program Files\Git"
$git_repos     = "C:\work\apexRepos"

# DB
$database="10.10.10.1:1521:GPI"


# PWD
$db_user     = "system"
$oracle_credential = "$scriptpath\ORACLE_CREDENTIAL.xml"

#
# To store the password we use  the PSCredential object
# if the serialized object of the password not exists
# prompt the user to enter the password
#

if (!(test-path -path $oracle_credential)) {
	$user_credential=GET-CREDENTIAL -credential "$db_user"  
	export-clixml -InputObject $user_credential -Path $oracle_credential
}
else {
   $user_credential=Import-Clixml -Path $oracle_credential
}

#get the clear type password

$db_password=$user_credential.GetNetworkCredential().Password 

# set the environment

set-item -path env:CLASSPATH   -value "$ora_odbc_lib;$apex_util_dir"
set-item -path env:GIT_HOME    -value "$git_home"
set-item -path env:JAVA_HOME   -value "$java_home"
 
#==============================================================================
# go to the git Repos


$repos_workspace="$git_repos\workspace"
if (!(test-path -path $repos_workspace)) {new-item -path $repos_workspace -itemtype directory}
Set-Location $repos_workspace
 
# Export all Workspaces 
& "$ENV:JAVA_HOME\bin\java"  oracle.apex.APEXExport  -db $database -user $db_user -password $db_password -expWorkspace 


$repos_report="$git_repos\interactiveReport"
if (!(test-path -path $repos_report)) {new-item -path $repos_report -itemtype directory}
Set-Location $repos_report

# -expSavedReports 
# & "$ENV:JAVA_HOME\bin\java"  oracle.apex.APEXExport  -db $database -user $db_user -password $db_password -expPubReports
#

$repos_instance="$git_repos\instance"
if (!(test-path -path $repos_instance)) {new-item -path $repos_instance -itemtype directory}
Set-Location $repos_instance

# Export the Instance

& "$ENV:JAVA_HOME\bin\java"  oracle.apex.APEXExport  -db $database -user $db_user -password $db_password -instance 2>&1 | foreach-object { local-print -text "JAVA OUT::",$_.ToString() }

#  alternativ Source Code exportieren only of one application
# java  oracle.apex.APEXExport  -db 10.10.10.1:1521:GPI -user system -password xxxxxx -applicationid 100


# Split the Code 
local-print -text  "Info -- Split the files in $git_repos\instance"

# Loop over all sql Files 
$sqlfiles = Get-ChildItem -Path "$git_repos\instance" -filter f*.sql 

for ($i=0; $i -lt $sqlfiles.Count; $i++) {
   # remove old not necessary
   # Remove-Item -Path $sqlfiles[$i].BaseName -Recurse -Force
   # Split the files   
   $appname=$sqlfiles[$i].BaseName
   local-print -text "Info -- Split App :: $appname"
   & "$ENV:JAVA_HOME\bin\java"  oracle.apex.APEXExportSplitter -update  $sqlfiles[$i].FullName 2>&1 | foreach-object { local-print -text "JAVA OUT::",$_.ToString() }
}


#==============================================================================
# GIT

Set-Location "$git_repos"

$datum = Get-Date
 
& "$ENV:GIT_HOME\cmd\git.exe" add .  2>&1 | foreach-object { local-print -text "GIT OUT::",$_.ToString() }
& "$ENV:GIT_HOME\cmd\git.exe" commit -m "Commit done by $env:UserName at $datum" 2>&1 | foreach-object { local-print -text "GIT OUT::",$_.ToString() }
# Push to remote if exists
#& "$ENV:GIT_HOME\cmd\git.exe" push
# Optimize database to avoid a too large db
& "$ENV:GIT_HOME\cmd\git.exe" gc 2>&1 | foreach-object { local-print -text "GIT OUT::",$_.ToString() }


local-print -text "Info -- Finish at :: $datum with user $env:UserName"
#  go back home

Set-Location $scriptpath

################### END ############################