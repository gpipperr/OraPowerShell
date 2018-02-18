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

#write-host "Info -- start the Script in the path $scriptpath"  -ForegroundColor "green"

#read the configuration file

$config_xml="$scriptpath\conf\oracle_tns.xml"
$oratns= [xml] ( get-content $config_xml)
	
# XML Version check
if ( $oratns.oracle_tns.HasAttribute("version") ) {
	$xml_script_version=$oratns.oracle_tns.getAttribute("version")
	if ( $CONFIG_VERSION.equals( $xml_script_version)) {
		#write-host "Info -- XML configuration with the right version::  $CONFIG_VERSION "
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
$global:ORACLE_ENV_LIST  =@()
$global:ORACLE_ENV_FGCOLOR =@()
$global:ORACLE_ENV_BGOLOR =@()



#Remember the old bg color
$global:fgcolor=(get-host).UI.RawUI.foregroundcolor;
$global:bgcolor=(get-host).UI.RawUI.backgroundcolor;

function cleanVars {
#unset this variables if exits
#FIX it not working like expacted ...

	if ($global:ENV_LIST) { 
		clear-variable -Name ENV_LIST             
	}
	if ($global:ORACLE_TNS_LIST) { 
		clear-variable -Name ORACLE_TNS_LIST      
	}
	if ($global:ORACLE_EASY_LIST) { 
		clear-variable -Name ORACLE_EASY_LIST     
	}
	if ($global:ORACLE_EASY_USER_LIST) { 
		clear-variable -Name ORACLE_EASY_USER_LIST
	}
	if ($global:search_db_env) { 
		clear-variable -Name search_db_env        
	}
	if ($global:search_db_name) { 
		clear-variable -Name search_db_name       
	}
	if ($global:ORACLE_ENV_LIST) { 
		clear-variable -Name ORACLE_ENV_LIST      
	}
	if ($global:ORACLE_ENV_FGCOLOR) { 
		clear-variable -Name ORACLE_ENV_FGCOLOR      
	}
	if ($global:ORACLE_ENV_BGOLOR) { 
		clear-variable -Name ORACLE_ENV_BGOLOR      
	}
	if ($global:bgcolor) {
		clear-variable -Name bgcolor    
	}
	if ($global:fgcolor) {
		clear-variable -Name fgcolor    
	}
}
#==============================================================================
# the functions of the script
#==============================================================================

# ext the script
function local-exit{
cleanVars
exit
}
#readEnviroment

function readENV{
#Read the EASY Connect identifier
	foreach ($easy_db in $oratns.oracle_tns.easy_connects.easy_connect) {
		$environment    = $easy_db.environment.InnerText;
		
		if ($environment) {
			$fgcolor="white"
			$bgcolor="blue"
			if (($easy_db.environment).GetAttribute("fgcolor")) {
				$fgcolor=($easy_db.environment).GetAttribute("fgcolor")
				#Write-host -ForegroundColor "red"  "Read FG Color:: $bgcolor"
			}			
			if (($easy_db.environment).GetAttribute("bgcolor")) {
				$bgcolor=($easy_db.environment).GetAttribute("bgcolor")
				#Write-host -ForegroundColor "red"  "Read BG Color:: $bgcolor"
			}		
			$global:ORACLE_ENV_LIST    += $environment			  
			$global:ORACLE_ENV_FGCOLOR += $fgcolor 
			$global:ORACLE_ENV_BGCOLOR += $bgcolor 
		}
	}
}
	
# read the XML get the the environments
function printEasyConnects {
	param(
		[String] $list_all , [String] $searchDB , [String] $searchEnv
	)
		
	$easy_connect_count=1
	
	#if null print all
	if ($list_all) {
		$list_all=$list_all;
	}
	else {
		$list_all="LIST_ALL_DBS";
	}
	
	if ($searchDB) {
		$searchDB=$searchDB;
	}
	else {
		$searchDB="LIST_ALL_DBS";
	}
	
	
	
	Write-host -ForegroundColor "red"  "Called with argument list_all :: $list_all - searchDB :: $searchDB - searchEnv :: $searchEnv"
	
	#Read the EASY Connect identifier
	foreach ($easy_db in $oratns.oracle_tns.easy_connects.easy_connect) {
	  
	  # if commend argument is empty then print everything
	  # if not print only this line
	  #
	    
		if ($list_all -eq "LIST_ALL_DBS" -or $list_all -eq "$easy_connect_count") {
		
			$environment    = $easy_db.environment.InnerText;
			$global_db_name = $easy_db.global_dbname.ToString();
			$sid            = $easy_db.sid.ToString();
			$service_name   = $easy_db.service_name.ToString();
			$dbhost         = $easy_db.dbhost.ToString();
			$port		    = $easy_db.port.ToString()
			$connect_string = "$dbhost"+":"+"$port/$service_name";					
					
			Write-host -ForegroundColor "red"  "found $environment"
			
			if 	($environment -imatch ([regex]::escape($searchEnv)) -or $searchEnv -eq "LIST_ALL_ENV" ) {	
				if 	($global_db_name -imatch ([regex]::escape($searchDB)) -or $searchDB -eq "LIST_ALL_DBS" ) {				
					
					Write-host -ForegroundColor "green"    " "("="*60)		
					Write-host -ForegroundColor "yellow"   ( "  +[{0,2}]              "  -f $easy_connect_count)						
					Write-host -ForegroundColor "green"    ( "  Environment     :: {0}"  -f $environment)			
					Write-host -ForegroundColor "green"    ( "  Global DB Name  :: {0}"  -f $global_db_name)
					Write-host -ForegroundColor "green"    ( "  Connect String  :: {0}"  -f $connect_string)
							
				}
			}
		}	
		
		#try to save this to a GLOBAL Variable:
		$global:ORACLE_EASY_LIST +=$connect_string
		if ($easy_db.default_user.ToString()) {
			$global:ORACLE_EASY_USER_LIST +=$easy_db.default_user.ToString()
		}
		else {
			$global:ORACLE_EASY_USER_LIST +="sys"
		}
		$easy_connect_count+=1
	}	
	Write-host -ForegroundColor "green"    " "("="*60)				
}	

# Ask the user for a search string the database
function answerSearchDB{

	$answer=Read-Host ( "{0,-40} [{1,-10}]:" -f "Please enter the Part of the DB name",$last_default_use_db)

	if ($answer) {
		if ($answer -imatch "^[Q]$") {
			local-exit		
		} 
		else {
			$global:search_db_name=$answer
		}
	}
	else {
		$global:search_db_name="LIST_ALL_DBS"
	}
}

# Ask the user for a search string for the enviroment
function answerSearchENV{
    #get a list with all unique environments
	
	$env_count=1
	
	foreach ( $element in ($global:ORACLE_ENV_LIST | sort -Unique) ) {
		Write-host -ForegroundColor "green"    ( "Env : [{0,-5}] :: {1}"  -f $element,$env_count )
		$env_count+=1
	}
	
	$valid_answer="false"
	
	do {

		$answer=Read-Host ( "{0,-52} :" -f "Please enter the No. of the DB environments")
		
		if ($answer) {
		
			# check if the answer is in the range of the List above
			try {
				if ($answer -imatch "^[1234567890QX]$" ) {
								
						if ($answer -imatch "^[Q]$") {
							local-exit		
						}
						if ($answer -imatch "^[A]$") {
							$global:search_db_env="LIST_ALL_ENV"							
						}
						else {
							$global:search_db_env=$global:ORACLE_ENV_LIST[$answer-1]						
						}		

						$valid_answer="true"		
					}	
				else {
					$valid_answer="false"
				}	
			}
			catch {
				write-host -ForegroundColor "red" $answer
				write-host $_.Exception.GetType().FullName; 
				write-host $_.Exception.Message; 
				$valid_answer="false"
			}
			
			if ($valid_answer.equals("false")) {
				Write-host -ForegroundColor "red" "Please enter a valid choice from the list above !"
			}	
			
		}
		else {
			$global:search_db_env="LIST_ALL_ENV"
			$valid_answer="true"		
		}
	}
	until ($valid_answer.equals("true"))
}


#==============================================================================
# Main section of the script
#==============================================================================

$Host.UI.RawUI.WindowTitle = "OraPowerShell --  call sql*plus"

local-print  -Text ("-"*80)
local-print  -Text "Info -- Call SQL*Plus to connect to a database"
local-print  -Text ("-"*80)

$answer="0";

#Read the possible environments
readENV

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
		local-exit
	}
	if ($answer -imatch "^[R]$" ) {
		#ask for the search string
		answerSearchENV
		answerSearchDB
		#print all
		printEasyConnects "LIST_ALL_DBS" "$global:search_db_name" "$global:search_db_env"
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

$connect_string=$username+"@""'"+$connect_string+"'"""

if ($username -imatch "^sys$"){
	$connect_string=$connect_string+" as sysdba"
}

local-print  -Text (" "*80)
local-print  -Text ("-"*80)
Write-host -ForegroundColor "red" "try to start sql*plus with this $connect_string"
local-print  -Text ("-"*80)
local-print  -Text (" "*80)

#==============================================================================
# set the bg color 
#
$env_fgcolor=$global:ORACLE_ENV_FGCOLOR[$answer-1]

$env_bgcolor=$global:ORACLE_ENV_BGCOLOR[$answer-1]

#(get-host).UI.RawUI.foregroundcolor=$env_fgcolor
#(get-host).UI.RawUI.backgroundcolor=$env_bgcolor

#==============================================================================
# start SQL*Plus

sqlplus "$connect_string"


#==============================================================================
# set the bg color  back
#

#(get-host).UI.RawUI.foregroundcolor = $global:fgcolor 
#(get-host).UI.RawUI.backgroundcolor = $global:bgcolor

#================================================================================
#
cleanVars

#==============================================================================
# error Handler
trap {
	Write-Host -foregroundcolor Yellow "-- Error Catch Exception see -> error Message: $($_.Exception.Message)"; 
	cleanVars 
}







