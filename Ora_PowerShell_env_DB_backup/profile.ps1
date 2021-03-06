#==============================================================================
# Author: Gunther Pipp�rr ( http://www.pipperr.de )
# Desc:   Profile for the Oracle Powershell enviroment
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

#==============================================================================
# Set-AuthenticodeSignature $profile @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
#==============================================================================

& {
 	$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
	$prp=new-object System.Security.Principal.WindowsPrincipal($wid)
	$adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
	$IsAdmin=$prp.IsInRole($adm)
 	# Hintergrund Farben setzen 
	if ($IsAdmin){
		(get-host).UI.RawUI.Backgroundcolor="DarkRed"    
	}
	else 
	{
		(get-host).UI.RawUI.BackgroundColor = "DarkBlue"    
	}
	(get-host).UI.RawUI.ForegroundColor = "white"
	clear-host
}

# Begr��ungs Screen
$d = get-Date -f dd.M.yyy
"Welcome the the Power Shell -- started at :: " + $d

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

###### Alias section
#

Import-Module "$scriptpath\setdb.psm1"

#### Switch to the working directory
#old cd $scriptpath
setWorkingDir

####
$wcount = @(Get-Process | Where-Object {$_.MainWindowTitle -like "OraPowerShell*"} | Select-Object MainWindowTitle ).Length + 1 
$Host.UI.RawUI.WindowTitle = "OraPowerShell Window Nr. $wcount"




