#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Run this Scripts as administrator to register the event source in the event log
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================
 
# Enviroment

# Script path
$scriptpath=get-location
$config_xml="$scriptpath\backup_config.xml"

# read Helper Functions
.  $scriptpath\backuplib.ps1

#==============================================================================

#check on Administrator
$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp=new-object System.Security.Principal.WindowsPrincipal($wid)
$adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
$IsAdmin=$prp.IsInRole($adm)
 
if ($IsAdmin) {
	local-register-eventlog
}
else{
	local-print -ForegroundColor "red"  -Text "--------------------------------------------------------------------"
	local-print -ForegroundColor "red"  -Text "You must start a administrative session to register the event source"
	local-print -ForegroundColor "red"  -Text "--------------------------------------------------------------------"
}	

#============================= End of File ====================================





