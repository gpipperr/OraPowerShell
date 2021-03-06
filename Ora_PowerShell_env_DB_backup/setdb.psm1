#==============================================================================
# Author: Gunther Pipp�rr ( http://www.pipperr.de )
# Desc:   Set the Oracle Enviroment in a PowerShell Enviroment
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

Set-StrictMode -Version 2.0

<#

	.NOTES
		Created: 09.2012 : Gunther Pipp�rr (c) http://www.pipperr.de			
		Security:  (see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
		To switch it off (as administrator)
		get-Executionpolicy -list
		set-ExecutionPolicy -scope CurrentUser RemoteSigned
		or sign code! 
		Set-AuthenticodeSignature .\setdb.ps1 @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
		to use as cmd-let set-alias setdb D:\OraPowerShellCodePlex\setdb.ps1 				
	.SYNOPSIS
		Set the enviroment for the Oracle Databases on this node, please configure oracle_homes.xml before use
	.DESCRIPTION
		Set the enviroment in the powershell to ot the right DB enviroment
	.PARAMETER Argument 1
		Number of the Oracle Home to have a quick select
	.COMPONENT
		Oracle Backup Script
	.EXAMPLE
		set the enviroment
		setdb 
		set the enviroment to the first db 
		setdb 1
#>
Set-Variable CONFIG_VERSION "0.2" -option constant


function setdb {
	[CmdletBinding()]
	param(
		 [int]    $dbnr
		,[String] $menue_mode = "false"
	)
    #======== Helper
	$liner= "---------------------------------------------------------"
 
	#======== Read the configuration file 

	$Invocation = (Get-Variable MyInvocation -Scope 0).Value
	$scriptpath=$Invocation.MyCommand.Module.ModuleBase
	$config_xml="$scriptpath\conf\oracle_homes.xml"
	$oraconfig= [xml] ( get-content $config_xml)
	
	# XML Version check
	if ( $oraconfig.oracle_homes.HasAttribute("version") ) {
		$xml_script_version=$oraconfig.oracle_homes.getAttribute("version")
		if ( $CONFIG_VERSION.equals( $xml_script_version)) {
			#debug write-host "Info -- XML configuration with the right version::  $CONFIG_VERSION "
		}
		else {
			throw "Configuration xml file version is wrong, found: $xml_script_version but need :: $CONFIG_VERSION !"
		}
	 }
	else {
		throw "Configuration xml file version info missing, please check the xml template from the new version and add the version attribute to <backup> !"
	}

	#======== Store the old Path in the Backkground
	try {
		if ($ENV:OLD_PATH) {
			# if exists do nothing
		}
		else {
			set-item -path ENV:OLD_PATH -value $ENV:PATH
		}
	}
	catch {
		"Old path is still set"
	}

	#======== the SQLPath Variable
	# if the path is not found use the default scriptpath/sql!
	#
	
	$sqlpath=$oraconfig.oracle_homes.sqlpath.toString()
	
	if ( Test-Path  $sqlpath) { 
	 # null
	}
	else {
		$sqlpath="$scriptpath\sql"
		write-host  -ForegroundColor "red" "Error -- Configuration of the SQLPATH is wrong - directory not extis :: using $scriptpath\sql as default"
	}
		
	try {
		set-item -path env:SQLPATH -value $sqlpath
	}
	catch {
		new-item -path env: -name SQLPATH -value $sqlpath
	}

	
	#========= TNSAdmin
	
	$tns_admin=$oraconfig.oracle_homes.tns_admin.toString()
	
	if ( Test-Path  $tns_admin) { 
		try {
			set-item -path env:TNS_ADMIN -value $tns_admin
		}
		catch {
			new-item -path env: -name TNS_ADMIN -value $tns_admin
		}
	}
	else {
		write-host  -ForegroundColor "red" "Error -- Configuration of the tns_admin is wrong - directory not extis :: $tns_admin"
	}		
	
	#========= NLS_LANG
	
	$nls_lang=$oraconfig.oracle_homes.nls_lang.toString()
	try {
		set-item -path env:NLS_LANG -value $nls_lang
	}
	catch {
		new-item -path env: -name NLS_LANG -value $nls_lang
	}
	
	#======== The Oracle Homes 
	
	# Array handling http://ss64.com/ps/syntax-arrays.html
	# 
	
	$ORACLE_HOME_LIST =@()
	$ORACLE_SID_LIST =@()
	
	$home_count=0
	$home_selector_default=0

	foreach ($orahome in  $oraconfig.oracle_homes.oracle_home ){
		
		if ("true".equals($menue_mode)) {
			$print_all=$false
		}
		else {
			$print_all=$true
		}			
		
		$ignoreHome=$orahome.enabled.toString()
		# show the home only if enabled!
		if ($ignoreHome.equals("true")) {
			#check if in menue mode (show only sid's)
			# FIXIT
			#
			
			Write-host -ForegroundColor "green" $liner
			
			$oracle_home =$orahome.path.ToString()
			$oracle_home_name =$orahome.oraname.ToString()
					
			Write-host -ForegroundColor "green"   "Oracle Home :: $oracle_home_name"
			Write-host -ForegroundColor "green"   "Oracle Path :: $oracle_home"
	
			foreach ($dbsid in  $orahome.db.sid ){
				$ORACLE_HOME_LIST +=$oracle_home
				
				$orasid=$dbsid.toString()
				if ($orasid.equals("false")) {
					$orasid="set no SID"
					$ORACLE_SID_LIST  +=""
					
				}
				else {
					$ORACLE_SID_LIST  +=$orasid
					$print_all=$true
				}
				$home_count+=1
				
				Write-host -ForegroundColor "yellow"  ( "  + [{0,2}]   {1}"  -f $home_count,$orasid)
			}
			Write-host -ForegroundColor "green" $liner
		}
	}
	    

	#======== read the answer
	$valid_answer="false"
	do {
		# check if the script is called with a parameter, if in use test the parameter if wrong show question
		if ($dbnr) {
			$home_selector=$dbnr
			$dbnr=""
		}
		else {
			$home_selector=Read-Host "Please enter the number of the Oracle Home:"
		}
		
		$valid_answer="false"
		
		# check if the answer is in the range of the $home_count
		try {
			#$home_selector -match "^[\d\]+$"
			if ($home_selector -match "^[0123456789]+$" ) {
			    if ($home_selector -gt 0 ) {
					if ($home_selector -lt $home_count+1 ){
						$valid_answer="true"
					}
				}
			}
		}
		catch {
			$valid_answer="false"
		}
		if ($valid_answer.equals("false")) {
			Write-host -ForegroundColor "red" "Please enter a vaild choise between 1 and $home_count !"
		}
	}
	until ($valid_answer.equals("true"))
	
	$home_count=$home_selector-1

	#======== set the enviroment
	# Oracle Home
	try {
		set-item -path env:ORACLE_HOME -value $ORACLE_HOME_LIST[$home_count]
	}
	catch {
		new-item -path env: -name ORACLE_HOME -value $ORACLE_HOME_LIST[$home_count]
	}
	# Oracle SID
	try {
		set-item -path env:ORACLE_SID -value $ORACLE_SID_LIST[$home_count]
	}
	catch {
		new-item -path env: -name ORACLE_SID -value $ORACLE_SID_LIST[$home_count]
	}
    # Path Variable
	set-item -path ENV:PATH -value $ENV:OLD_PATH
	$ora_bin=$ENV:ORACLE_HOME+"\bin;"
	$ENV:PATH = $ora_bin+$ENV:PATH

    #======== show the resut
	write-host -ForegroundColor "green" $liner
	write-host -ForegroundColor "green" "set the ORACLE_HOME to ::" $ENV:ORACLE_HOME 
	write-host -ForegroundColor "green" "set the ORALCE_SID  to ::" $ENV:ORACLE_SID
	write-host -ForegroundColor "green" $liner
	$titleString=$Host.UI.RawUI.WindowTitle 
	$Host.UI.RawUI.WindowTitle = "$titleString SID: $ENV:ORACLE_SID"

	. Remove-Item variable:ORACLE_HOME_LIST
	. Remove-Item variable:ORACLE_SID_LIST

}



function setWorkingDir {
	[CmdletBinding()]
	param(
		 [int]    $dbnr
		,[String] $menue_mode = "false"
	)
    #======== Helper
	$liner= "---------------------------------------------------------"
 
	#======== Read the configuration file 

	$Invocation = (Get-Variable MyInvocation -Scope 0).Value
	$scriptpath=$Invocation.MyCommand.Module.ModuleBase
	$config_xml="$scriptpath\conf\oracle_homes.xml"
	
	$oraconfig= [xml] ( get-content $config_xml)
	
	$workingDirectory=$oraconfig.oracle_homes.work_directory.toString()
	
	cd $workingDirectory
}



