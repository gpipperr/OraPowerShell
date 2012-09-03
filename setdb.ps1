########################################
# Set-AuthenticodeSignature .\setdb.ps1 @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
########## Enviroment      ##############

try {
	set-item -path ENV:OLD_PATH -value $ENV:PATH
}
catch {
	"Old path is still set"
}

try {
	set-item -path env:SQLPATH -value "D:\scripts"
}
catch {
	new-item -path env: -name SQLPATH -value "D:\scripts"
}

########## The Oracle Homes #############
# Array handling http://ss64.com/ps/syntax-arrays.html
# 

$ORACLE_HOME =@()
$ORACLE_HOME_NAME =@()

$ORACLE_HOME +="D:\oracle\product\11.2.0.3\client_32bit"
$ORACLE_HOME_NAME +="Client 32Bit"

$ORACLE_HOME +="D:\oracle\product\11.2.0.3\client_64bit"
$ORACLE_HOME_NAME +="Client 64Bit"

$ORACLE_HOME +="D:\oracle\product\11.2.0.3\dbhome_1"
$ORACLE_HOME_NAME +="DB Home"

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

$title   = "Set the Oracle Enviroment"
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

