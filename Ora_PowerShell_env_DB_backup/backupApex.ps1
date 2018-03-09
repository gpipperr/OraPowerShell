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

# Environment

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

write-host "Info -- start the Script in the path $scriptpath"  -ForegroundColor "green"	

# Runtime Parameter

$apex_util_dir = "C:\oracle\apex\utilities\"
$ora_odbc_lib  = "C:\oracle\products\12.2.0.1\dbhome_1\jdbc\lib\ojdbc8.jar"
$java_home     = "C:\Program Files\Java\jdk1.8.0_112"
$git_home      = "C:\Program Files\Git"
$git_repos     = "C:\work\apexRepos"

# DB
$database="10.10.10.1:1521:GPI"


#PWD
# FIX PWD encrpytion!!
$db_user     = "system"
$db_password = "xxxxxxxx" #  next version will encrypt PWD local-read-secureString -text $db_password_encrypt

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

& "$ENV:JAVA_HOME\bin\java"  oracle.apex.APEXExport  -db $database -user $db_user -password $db_password -instance

#  alternativ Source Code exportieren only of one application
# java  oracle.apex.APEXExport  -db 10.10.10.1:1521:GPI -user system -password xxxxxx -applicationid 100


# Split the Code 
write-host "Info -- Split the files in $git_repos\instance"  -ForegroundColor "green"	

# Loop over all sql Files 
$sqlfiles = Get-ChildItem -Path "$git_repos\instance" -filter f*.sql 

for ($i=0; $i -lt $sqlfiles.Count; $i++) {
   # remove old not necessary
   # Remove-Item -Path $sqlfiles[$i].BaseName -Recurse -Force
   # Split the files
   write-host "Info -- Split App :: " $sqlfiles[$i].BaseName
   & "$ENV:JAVA_HOME\bin\java"  oracle.apex.APEXExportSplitter -update  $sqlfiles[$i].FullName
}


#==============================================================================
# GIT

Set-Location "$git_repos"

$datum = Get-Date
 
& "$ENV:GIT_HOME\cmd\git.exe" add .
& "$ENV:GIT_HOME\cmd\git.exe" commit -m "Commit done by $env:UserName at $datum"
# Push to remote if exists
#& "$ENV:GIT_HOME\cmd\git.exe" push

################### END ############################