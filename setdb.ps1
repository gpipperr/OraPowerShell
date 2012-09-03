################## set Oracle Enviroment  ###############################
<#

	Security:  (see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
  
	To switch it off (as administrator)
  
	get-Executionpolicy -list
	set-ExecutionPolicy -scope CurrentUser RemoteSigned
  
	or sign code! 
  
	Set-AuthenticodeSignature .\setdb.ps1 @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]

	to use as cmd-let set-alias setdb D:\OraPowerShellCodePlex\setdb.ps1 
 
	.NOTES
		Created: 09.2012 : Gunther Pippèrr (c) http://www.pipperr.de				
	.SYNOPSIS
		Set the enviroment foOracle Database 
	.DESCRIPTION
		Set the enviroment in the powershell to ot the right DB enviroment
	.PARAMETER argumet 1
		Number of the Oracle Home to have a quick select
	.COMPONENT
		Oracle Backup Script
	.EXAMPLE
		set the enviroment
		setdb 
		set the enviroment to the first db 
		setdb 1
#>

###### Read the configuration file 

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

$config_xml="$scriptpath\conf\oracle_homes.xml"

# read Configuration
$oraconfig= [xml] ( get-content $config_xml)


###### Store the old Path in the Backkground
try {
	set-item -path ENV:OLD_PATH -value $ENV:PATH
}
catch {
	"Old path is still set"
}

# set the SQLPath Variable
try {
	set-item -path env:SQLPATH -value "$scriptpath\sql"
}
catch {
	new-item -path env: -name SQLPATH -value "$scriptpath\sql"
}


########## The Oracle Homes #############
# Array handling http://ss64.com/ps/syntax-arrays.html
# 

$ORACLE_HOME =@()
$ORACLE_HOME_NAME =@()

foreach ($orahome in  $oraconfig.oracle_homes.oracle_home ){
	$ORACLE_HOME +=$orahome.path.ToString()
	$ORACLE_HOME_NAME +=$orahome.oraname.ToString()
}

#######################################

$options = [System.Management.Automation.Host.ChoiceDescription[]]@()
$C=0
# Create the option Array
# & markiet das Label für den Hotkey
# http://msdn.microsoft.com/en-us/library/system.management.automation.host.choicedescription_members%28v=vs.85%29

foreach ($H in $ORACLE_HOME_NAME ) {
	$C +=1
	$label=$H+" &"+$C
	$HMessage="Use the oracle enviroment "+$H
	$options +=  New-Object System.Management.Automation.Host.ChoiceDescription( $label, $HMessage)
}

write-host "-------------------------------------" -ForegroundColor "yellow"

$title   = "Set the Oracle Enviroment V1.1"
$message = "Please choose the Oracle Enviromen you like to use"

$result = $host.ui.PromptForChoice($title, $message, [System.Management.Automation.Host.ChoiceDescription[]] $options, 0) 

write-host "-------------------------------------" -ForegroundColor "yellow"

try {
	set-item -path env:ORACLE_HOME -value $ORACLE_HOME[$result]
}
catch {
	new-item -path env: -name ORACLE_HOME -value $ORACLE_HOME[$result]
}

set-item -path ENV:PATH -value $ENV:OLD_PATH
$ora_bin=$ENV:ORACLE_HOME+"\bin;"
$ENV:PATH = $ora_bin+$ENV:PATH

write-host "set the ORACLE_HOME to ::"  $ENV:ORACLE_HOME

#
#switch ($result) {
#        0 {     }
#        1  {     }
#  }
  
Remove-Item variable:options
Remove-Item variable:c
Remove-Item variable:ORACLE_HOME
Remove-Item variable:ORACLE_HOME_NAME

