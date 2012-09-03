###############################################################
# Set-AuthenticodeSignature $profile @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
#
###############################################################
& {
 
  $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
  $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
  $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  $IsAdmin=$prp.IsInRole($adm)
 
  # Hintergrund Farben setzen 
  if ($IsAdmin)
  {
    (get-host).UI.RawUI.Backgroundcolor="DarkRed"    
  }
  else {
 
    (get-host).UI.RawUI.BackgroundColor = "blue"    
  }
  (get-host).UI.RawUI.ForegroundColor = "white"
  clear-host
}
 
# Begrüßungs Screen
$d = get-Date -f dd.M.yyy
"Welcome the the Power Shell started :: " + $d

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

###### Alias section
set-alias setdb "$scriptpath\setdb.ps1"
####

cd $scriptpath

####