#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   start SQL*Plus for a selected DB on  host and port and service
#         use an xml template to read the possible connection - oracle_tns.xml
#
# Date:   10.07.2014
# Site:   http://orapowershell.codeplex.com
#==============================================================================

<#
 	.NOTES
		Created: 07.2014 : Gunther Pippèrr (c) http://www.pipperr.de
		Security:
			(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
			
			to start the script bypass the security:
			%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File d:\PowerShell\certScripts.ps1
			
	.SYNOPSIS
		Script to start sqlplus
	.DESCRIPTION
		Script to start sqlplus
	.COMPONENT
		Oracle Maintainance Scripts
#>

#==============================================================================
# Environment
Set-Variable CONFIG_VERSION "0.2" -option constant

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path
cd  $scriptpath

# read Helper Functions
.  $scriptpath\lib\backuplib.ps1

write-host "Info -- start the Script in the path $scriptpath"  -ForegroundColor "green"

#read the configuration file

$config_xml="$scriptpath\conf\oracle_tns.xml"
$oratns= [xml] ( get-content $config_xml)
	
# XML Version check
if ( $oratns.oracle_tns.HasAttribute("version") ) {
	$xml_script_version=$oratns.oracle_tns.getAttribute("version")
	if ( $CONFIG_VERSION.equals( $xml_script_version)) {
		write-host "Info -- XML configuration with the right version::  $CONFIG_VERSION "
	}
	else {
		throw "Configuration XML file version is wrong, found: $xml_script_version but need :: $CONFIG_VERSION !"
	}
}
else {
	throw "Configuration XML file version info missing, please check the XML template from the new version and add the version attribute to <backup> !"
}	

#==============================================================================
#Global
	
$global:ENV_LIST         =@()
$global:ORACLE_TNS_LIST  =@()
$global:ORACLE_EASY_LIST =@()
$global:ORACLE_EASY_USER_LIST =@()
$global:search_db_env  = "LIST_ALL_ENV"
$global:search_db_name = "LIST_ALL_DBS"
$global:ORACLE_ENV_LIST =@()

#==============================================================================
# the functions of the script
#==============================================================================
	
# read the XML get the the environments
function printEasyConnects {
	param(
		[String] $command_arg , [String] $search , [String] $dbenv
	)
		
	$easy_connect_count=1
	
	#if null print all
	if ($command_arg) {
		$command_arg=$command_arg;
	}
	else {
		$command_arg="PRINT_ALL";
	}
	
	Write-host -ForegroundColor "red"  "Called with argument command_arg :: $command_arg - search ::" + escape($search)
	
	#Read the EASY Connect identifier
	foreach ($easy_db in $oratns.oracle_tns.easy_connects.easy_connect) {
	  
	  # if commend argument is empty then print everything
	  # if not print only this line
	  #
	    
		if ($command_arg -eq "PRINT_ALL" -or $command_arg -eq "$easy_connect_count") {
		
			$environment    = $easy_db.environment.ToString();
			$global_db_name = $easy_db.global_dbname.ToString();
			$sid            = $easy_db.sid.ToString();
			$service_name   = $easy_db.service_name.ToString();
			$dbhost         = $easy_db.dbhost.ToString();
			$port		    = $easy_db.port.ToString()
			$connect_string = "$dbhost"+":"+"$port/$service_name";					
					
			
			if 	($environment -imatch ([regex]::escape($dbenv)) -or $dbenv -eq "LIST_ALL_ENV" ) {	
				if 	($global_db_name -imatch ([regex]::escape($search)) -or $search -eq "LIST_ALL_DBS" ) {				
					Write-host -ForegroundColor "green"    ("="*80)				
					Write-host -ForegroundColor "green"    ( "Global DB Name   ::  {0}"     -f $global_db_name)
					Write-host -ForegroundColor "green"    ( "Connect String   ::  {0}"     -f $connect_string)
					Write-host -ForegroundColor "yellow"   ( "Environment[{0,2}]  ::  {1}"  -f $easy_connect_count,$environment)					
				}
			}
		}	
		
		#try to save this to a GLOBAL Variable:
		$global:ORACLE_EASY_LIST +=$connect_string
		$global:ORACLE_ENV_LIST   +=$environment
		if ($easy_db.default_user.ToString()) {
			$global:ORACLE_EASY_USER_LIST +=$easy_db.default_user.ToString()
		}
		else {
			$global:ORACLE_EASY_USER_LIST +="sys"
		}
		$easy_connect_count+=1
	}	
	Write-host -ForegroundColor "green"    ("="*80)				
}	

# Ask the user for a search string the database
function answerSearchDB{

	$global:search_db_name=Read-Host ( "{0,-40} [{1,-10}]:" -f "Please enter the Part of the DB name",$last_default_use_db)

	if ($global:search_db_name) {
		$global:search_db_name=$global:search_db_name
	}
	else {
		$global:search_db_name="LIST_ALL_DBS"
	}
}

# Ask the user for a search string for the enviroment
function answerSearchENV{
    #get a list with all unique environments
	#$global:ORACLE_ENV_LIST=@($global:ORACLE_ENV_LIST | select –unique)
	
	$global:search_db_env=Read-Host ( "{0,-40} [{1,-10}]:" -f "Please enter the DB environments",$global:ORACLE_ENV_LIST[1])

	if ($global:search_db_env) {
		$global:search_db_env=$global:search_db_env
	}
	else {
		$global:search_db_env="LIST_ALL_ENV"
	}
}


#==============================================================================
# Main section of the script
#==============================================================================

$Host.UI.RawUI.WindowTitle = "OraPowerShell --  call sql*plus"

local-print  -Text ("-"*80)
local-print  -Text "Info -- Call SQL*Plus to connect to a database"
local-print  -Text ("-"*80)

$answer="0";

#$global:ORACLE_ENV_LIST

#ask for the search string
answerSearchENV
answerSearchDB
#print selected
printEasyConnects $args[0] "$global:search_db_name" "$global:search_db_env"

 do {
 	# called with command parameter one
	
 	if ( $args[0]) {
 		 $answer =  $args[0]
 	}
 	else {	   
		$answer=Read-Host ("{0,-53}:" -f "Please enter the Number of the connection")
 		$answer=$answer.toUpper()
 	
	}
 	
 	$valid_answer="false"
	
	if ($answer -imatch "^[EQ]$" ) {
		return
	}
	if ($answer -imatch "^[R]$" ) {
		#ask for the search string
		answerSearchENV
		answerSearchDB
		#print all
		printEasyConnects "PRINT_ALL" "$global:search_db_name" "$global:search_db_env"
	}
 	
 	# check if the answer is in the range of the List above
 	try {
 		if ($answer -imatch "^[1234567890Q]$" ) {
		    $valid_answer="true"
 		}	
		
 	}
 	catch {
 		$valid_answer="false"
 	}
 	
 	if ($valid_answer.equals("false")) {
 		Write-host -ForegroundColor "red" "Please enter a valid choice from the list above !"
 	}	
}
until ($valid_answer.equals("true"))

$default_user=$global:ORACLE_EASY_USER_LIST[$answer-1]

$username=Read-Host ("{0,-40} [{1,-10}]:" -f "Please enter the Name of the User",$default_user )

if ($username) {
	$username=$username
}
else {
	$username=$default_user
}

		
# ==== Call SQL Plus
$connect_string=$global:ORACLE_EASY_LIST[$answer-1]

$connect_string=$username+"@"+$connect_string

if ($username -imatch "^sys$"){
	$connect_string=$connect_string+" as sysdba"
}

local-print  -Text (" "*80)
local-print  -Text ("-"*80)
Write-host -ForegroundColor "red" "try to start sql*plus with this $username@$connect_string"
local-print  -Text ("-"*80)
local-print  -Text (" "*80)

sqlplus "$username@$connect_string"


