#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Library for the backup scripts
# Date:   08.Oktober 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

<#
 	.NOTES
		Created: 10.2012 : Gunther Pippèrr (c) http://www.pipperr.de
		Security:
			(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
			
			to start the script bypass the security:
			%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File d:\PowerShell\certScripts.ps1
			
	.SYNOPSIS
		Script to create the certificate and sign all scipts
	.DESCRIPTION
		Script to create the certificate and sign all scipts
	.COMPONENT
		Oracle Backup Script
#>

#==============================================================================
# Enviroment
Set-Variable CONFIG_VERSION "0.2" -option constant

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

write-host "Info -- start the Script in the path $scriptpath"  -ForegroundColor "green"

cd  $scriptpath

# read Helper Functions
.  $scriptpath\lib\backuplib.ps1


#==============================================================================
#create private Certificate
function local-createPrivCert {
	local-print  -Text "Info --  create new private zertificate"
	# check for cert programm
	local-print  -Text "Info --  Check for the cert programm"
    #http://www.microsoft.com/en-us/download/details.aspx?id=8279
	$cert_prog="C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\makecert"
	# create a local root certificate
	& $cert_prog -n "CN=Local Certificate" -a sha1 -eku 1.3.6.1.5.5.7.3.3 -r -sv root.pvk root.cer -ss Root -sr localMachine
	
	# create the certificate
	& $cert_prog -pe -n "CN=PowerShell User" -ss MY -a sha1 -eku 1.3.6.1.5.5.7.3.3 -iv root.pvk -ic root.cer
	
	
	# show the certificate
	Get-ChildItem cert:\CurrentUser\My -codesign
}

#==============================================================================
# B export certificate
# as PKCS #12  (PFX-Format)

function local-exportCert {
	# read the cert
	$cert = (dir cert:\currentuser\my)  # check on arry[0]
	# define the type
	$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::pfx
	# the the password of the certificate
	$pass = read-host "pass" -assecurestring 
	# export as byteset
	$bytes = $cert.export($type, $pass)
	# write to file
	[System.IO.File]::WriteAllBytes("$scriptpath\mycert.pfx", $bytes)
}

#==============================================================================
# C import certificate
# see http://www.orcsweb.com/blog/james/powershell-ing-on-windows-server-how-to-import-certificates-using-powershell/
#
#
function import-exportCert {
	param(	 [String]$certPath
			,[String]$certRootStore = "CurrentUser"
			,[String]$certStore 	= "My"
			,$pfxPass 				= $null
		)    
	$pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2    
 
	if ($pfxPass -eq $null) {
		$pfxPass = read-host “Enter the pfx password” -assecurestring
	}    
 
	$pfx.import($certPath,$pfxPass,"Exportable,PersistKeySet")    
	
	$store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)    
	
	$store.open("MaxAllowed")    
	$store.add($pfx)    
	$store.close()    
}

#==============================================================================
# D show all possilbe certificates
function local-showCert{
	# show the certificate
	Get-ChildItem cert:\CurrentUser\My -codesign
}


#==============================================================================
# F sign all ps1 scripts in the script library
function local-signScripts {
	local-print  -Text "Info -- sign all scripts"
	Set-AuthenticodeSignature .\myscript.ps1 @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
}

#==============================================================================
#G show the security settings
function local-showSecSettings {
	local-print  -Text "Info --  the actual security settings"
	get-Executionpolicy -list
}

#==============================================================================
# H set the security settings
function local-showSecSettings {
	local-print  -Text "Info --  set actual security settings"
	Set-ExecutionPolicy –scope CurrentUser AllSigned
}


#==============================================================================
# command switch
# A create private Certificate
# B export certificate
# C import certificate
# D show all possilbe certificates
# F sign all ps1 scripts in the script library
# G show the security settings
# H set the security settings
#==============================================================================

#check on Administator
$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp=new-object System.Security.Principal.WindowsPrincipal($wid)
$adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
$IsAdmin=$prp.IsInRole($adm)
 
if ($IsAdmin) {
	# List the options
	
	# Ask questions
	$answer=Read-Host "Please enter the command you like to do:"
	
	
}
else{
	local-print -ForegroundColor "red"  -Text "--------------------------------------------------------------------"
	local-print -ForegroundColor "red"  -Text "You must start a administrative session to deal with certificates"
	local-print -ForegroundColor "red"  -Text "--------------------------------------------------------------------"
}
#==============================================================================