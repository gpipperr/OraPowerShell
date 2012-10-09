#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Library for the backup scripts
# Date:   08.Oktober 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================
# Other Examples:
# http://www.powershellpraxis.de/index.php/zertifikate-pki/psskripte-signieren
# http://poshcode.org/1473
# http://www.hanselman.com/blog/SigningPowerShellScripts.aspx
#
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
# the functions of the script
#==============================================================================

#==============================================================================
# A) create private Certificate
#
function local-createPrivCert {
	param(	 [String]$certRootStore = "CurrentUser"
			,[String]$certStore 	= "My"
			,$pfxPass 				= $null
	)    
	local-print  -Text "Info --  create new private certificat" -ForegroundColor "yellow"
	# check for cert programm
	local-print  -Text "Info --  Check for the cert programm"

	# password must be entered in window!
	#if ($pfxPass -eq $null) {
	#	$pfxPass = read-host "Enter the certificate password" -assecurestring
	#}    
	
	# try to find the cert programm
	# 
	#$cert_prog="C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\makecert.exe"
	
	# Path to search for the cert program
	$cert_prog_path="C:\Program Files\Microsoft SDKs\*"
	
	# search after the cert programm and use the last match
	foreach ( $cert_prog in (Get-ChildItem -Recurse -Include "makecert.exe" -Path $cert_prog_path ) ) { }
	
	local-print  -Text "info -- use the makecert from $cert_prog"
	
	#get-Childitem $cert_prog -ErrorAction silentlycontinue
	if ($cert_prog) {
	
	<#
		Usage: MakeCert [ basic|extended options] [outputCertificateFile]
		Extended Options
		 -tbs <file>         Certificate or CRL file to be signed
		 -sc  <file>         Subject's certificate file
		 -sv  <pvkFile>      Subject's PVK file; To be created if not present
		 -ic  <file>         Issuer's certificate file
		 -ik  <keyName>      Issuer's key container name
		 -iv  <pvkFile>      Issuer's PVK file
		 -is  <store>        Issuer's certificate store name.
		 -ir  <location>     Issuer's certificate store location
								<CurrentUser|LocalMachine>.  Default to 'CurrentUser'
		 -in  <name>         Issuer's certificate common name.(eg: Fred Dews)
		 -a   <algorithm>    The signature algorithm
								<md5|sha1|sha256|sha384|sha512>.  Default to 'sha1'
		 -ip  <provider>     Issuer's CryptoAPI provider's name
		 -iy  <type>         Issuer's CryptoAPI provider's type
		 -sp  <provider>     Subject's CryptoAPI provider's name
		 -sy  <type>         Subject's CryptoAPI provider's type
		 -iky <keytype>      Issuer key type
								<signature|exchange|<integer>>.
		 -sky <keytype>      Subject key type
								<signature|exchange|<integer>>.
		 -l   <link>         Link to the policy information (such as a URL)
		 -cy  <certType>     Certificate types
								<end|authority>
		 -b   <mm/dd/yyyy>   Start of the validity period; default to now.
		 -m   <number>       The number of months for the cert validity period
		 -e   <mm/dd/yyyy>   End of validity period; defaults to 2039
		 -h   <number>       Max height of the tree below this cert
		 -len <number>       Generated Key Length (Bits)
		 -r                  Create a self signed certificate
		 -nscp               Include Netscape client auth extension
		 -crl                Generate a CRL instead of a certificate
		 -eku <oid[<,oid>]>  Comma separated enhanced key usage OIDs
		 -?                  Return a list of basic options
		 -!                  Return a list of extended options
	#>
	
	
		# create a local root certificate
		local-print  -Text "Info -- create a local root certificate"
		& $cert_prog -n "CN=Local Selfsign Certificate" -a sha1 -eku 1.3.6.1.5.5.7.3.3 -r -sv "$scriptpath\cert\root.pvk" "$scriptpath\cert\root.cer" -ss Root -sr localMachine
		
		# create the certificate
		local-print  -Text "Info -- create the user certificate"
		& $cert_prog -pe -n "CN=OraPowerShell SelfSignCert" -ss MY -a sha1 -eku 1.3.6.1.5.5.7.3.3 -iv "$scriptpath\cert\root.pvk" -ic "$scriptpath\cert\root.cer"
		
		# show the certificate
		local-showCert
	}
	else {
		local-print  -ErrorText "Error - makecert not found in $cert_prog_path"
		local-print  -ErrorText ("-"*80)
		local-print  -ErrorText "You can download makecert.exe from http://www.microsoft.com/en-us/download/details.aspx?id=8279"
		local-print  -ErrorText ("-"*80)
	}
}

#==============================================================================
# B) export certificate
# as PKCS #12  (PFX-Format)
#
function local-exportCert {
	param(	 [String]$certPath  	= "$scriptpath/cert/myusercert.pfx"
			,[String]$certRootStore = "CurrentUser"
			,[String]$certStore 	= "My"
	)    
	local-print  -Text "Info -- try to export the certificat to $certPath" -ForegroundColor "yellow"
	
	# define the type
	$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::pfx
	
	# search for the certificate to export
	$use_this_certificate=local-choose-certificate -certRootStore $certRootStore -certStore $certStore
	
	if ($use_this_certificate) {
		
		$cert=$use_this_certificate
		
		# the the password of the certificate
		$pass = read-host "pass" -assecurestring 
		# export as byteset
		$bytes = $cert.export($type, $pass)
		# write to file
		[System.IO.File]::WriteAllBytes($certPath, $bytes)
	}
	else {
		local-print -ErrorText "Error -- certificate is null"
	}
}

#==============================================================================
# C) import certificate
# see http://www.orcsweb.com/blog/james/powershell-ing-on-windows-server-how-to-import-certificates-using-powershell/
#
function local-importCert {
	param(	 [String]$certPath  	= "$scriptpath/cert/myusercert.pfx"
			,[String]$certRootStore = "CurrentUser"
			,[String]$certStore 	= "My"
			,$pfxPass 				= $null
		)    
	local-print  -Text "Info -- try to import the certificat from $certPath" -ForegroundColor "yellow"
	
	$pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2    
 
	if ($pfxPass -eq $null) {
		$pfxPass = read-host "Enter the pfx password" -assecurestring
	}    
 
	$pfx.import($certPath,$pfxPass,"Exportable,PersistKeySet")    
	
	$store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)    
	
	$store.open("MaxAllowed")    
	$store.add($pfx)    
	$store.close()    
}

#==============================================================================
# D) show all possilbe certificates for code signing
#
function local-showCert{
	param(	 [String]$certRootStore = "CurrentUser"
			,[String]$certStore 	= "My"
	)
	local-print  -Text "Info -- show the existing certificates for code signing" -ForegroundColor "yellow"
	# show the certificate
	$counter=1
	foreach ( $cert in (Get-ChildItem "cert:\$certRootStore\$certStore" -codesign) ) {
		local-print  -Text ( "[{0}] Subject::{1,40}  Thumbprint::{2}" -f $counter,$cert.Subject,$cert.Thumbprint )
		$counter++
	}
}

#==============================================================================
# E) sign all ps1 scripts in the script library
#
function local-signScripts {
	local-print  -Text "Info -- sign all scripts" -ForegroundColor "yellow"
	
	# search for the certificate to sign
	$use_this_certificate=local-choose-certificate -certRootStore $certRootStore -certStore $certStore
	
	# find all ps1 and psm scripts in the script patch
	foreach ( $script in (Get-ChildItem -Recurse -Include "*.ps1","*.psm1" -Path $scriptpath ) ) {
		local-print  -Text "Info -- sign script $script"
		Set-AuthenticodeSignature $script $use_this_certificate
		Get-AuthenticodeSignature $script
	}
	local-print  -Text "Info -- sign the default profile script of this session" -ForegroundColor "yellow"
	Set-AuthenticodeSignature $profile $use_this_certificate
	Get-AuthenticodeSignature $profile
}

#==============================================================================
# F) show the security settings
#
function local-showSecSettings {
	local-print  -Text "Info --  the actual security settings:" -ForegroundColor "yellow"
	get-Executionpolicy -list | Format-List
}

#==============================================================================
# G) set the security settings
#
function local-setSecSettings {
	
	local-print  -Text "Info --  set actual security settings to AllSigned "  -ForegroundColor "yellow"
	
	Set-ExecutionPolicy –scope CurrentUser AllSigned
	local-showSecSettings
}

#==============================================================================
# I) set the security settings
#
function local-resetSecSettings {
	
	local-print  -Text "Info --  set actual security settings to RemoteSigned "  -ForegroundColor "yellow"
	
	Set-ExecutionPolicy –scope CurrentUser RemoteSigned
	local-showSecSettings
}

#==============================================================================
# J) remove the signature
#

function local-removeSignature {
	local-print  -Text "Info -- remove signature from all scripts" -ForegroundColor "yellow"
	$file_content=$null
	
	# find all ps1 and psm scripts in the script patch
	foreach ( $script in (Get-ChildItem -Recurse -Include "*.ps1","*.psm1" -Path $scriptpath ) ) {
		local-print  -Text "Info -- remove signature from script::$script"
		#remove
		$file_content=$null
		$stop_process=$false
		# break will jump out of the whole loop, not only in the pipline ....
		get-content $script | %{ if ( $stop_process -eq $false ) { if ($_ -eq '# SIG # Begin signature block') { $stop_process=$true } else { $file_content+=$_; $file_content+=$CLF } } }
		set-content -Path $script -value $file_content
	}
	
	# remove the signature from the profile of the user
	local-print  -Text "Info -- remove signature from the default profile script of this session $profile" -ForegroundColor "yellow"
	$file_content=$null
	#remove
	get-content $profile | %{if ($_ -eq '# SIG # Begin signature block') {break} else {$file_content+=$_; $file_content+=$CLF}}
	Set-content -Path $profile -value $file_content

}
#==============================================================================
# show a list of certificates
#
function local-choose-certificate {
 	param(	 [String]$certRootStore = "CurrentUser"
			,[String]$certStore 	= "My"
	)
	
	local-print  -Text "Info -- List of certificates - please choose the certificat"
	
	# show the certificate
	$counter=1
	$cert_arry=@()
	
	foreach ( $cert in (Get-ChildItem "cert:\$certRootStore\$certStore" -codesign) ) {
		local-print  -Text ( "[{0}] Subject::{1,40}  Thumbprint::{2}" -f $counter,$cert.Subject,$cert.Thumbprint )
		$cert_arry+=$cert
		$counter++
	}
	do {
		# Ask questions
		$cert_answer=Read-Host "Please enter the number of the certificate to use [1]:"
		
		if ($cert_answer) {
		 # check for valid answer later
		}
		else {
			$cert_answer=1
		}
		
		$valid_answer="false"
		
		# check if the answer is in the range of the $home_count
		try {
			#$home_selector -match "^[\d\]+$"
			if ($cert_answer -match "^[0123456789]+$" ) {
			    if ($cert_answer -gt 0 ) {
					if ($cert_answer -lt $counter ){
						$valid_answer="true"
					}
				}
			}
		}
		catch {
			$valid_answer="false"
		}
		if ($valid_answer.equals("false")) {
			local-print -ErrorText ("Please enter a vaild choise between 1 and {0} !" -f ($counter-1) )
		}
	} until ($valid_answer.equals("true"))
	
	$USE_THIS_CERTIFICATE=$cert_arry[$cert_answer-1]
	
	local-print  -Text ("You choose the certificate::{0}" -f $USE_THIS_CERTIFICATE.subject)
	
	return $USE_THIS_CERTIFICATE
	
}

#==============================================================================
# Main section of the script
#==============================================================================

#==============================================================================
# command switch
# A create private Certificate
# B export certificate
# C import certificate
# D show all possilbe certificates
# E sign all ps1 scripts in the script library
# F show the security settings
# G set the security settings
# I set the security settings to nothing"
# J remove the signature"
# X exit"
#==============================================================================

#check on Administator
$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp=new-object System.Security.Principal.WindowsPrincipal($wid)
$adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
$IsAdmin=$prp.IsInRole($adm)
 
if ($IsAdmin) {
	
	local-print  -Text ("-"*80)
	local-print  -Text "Info -- Setup script for the certificate handling of the the backup script library"
	local-print  -Text ("-"*80)
	
	do {
		# called wiht command parameter one
		if ( $args[0]) {
			$answer =  $args[0]
		}
		else {
			# List the options
			local-print  -Text " ------> choose a option from the list:"
			local-print  -Text " [A] --> create private Certificate"
			local-print  -Text " [B] --> export certificate"
			local-print  -Text " [C] --> import certificate"
			local-print  -Text " [D] --> show all possilbe certificates"
			local-print  -Text " [E] --> sign all ps1 scripts in the script library"
			local-print  -Text " [F] --> show the security settings"
			local-print  -Text " [G] --> set the security settings to signed scripts"
			local-print  -Text " [I] --> set the security settings to nothing"
			local-print  -Text " [J] --> remove the signature"
			local-print  -Text " [X] --> exit"
			# Ask questions
			$answer=Read-Host "Please enter the command you like to do:"
			$answer=$answer.toUpper()
		}
		
		$valid_answer="false"
		
		# check if the answer is in the range of the List above
		try {
			if ($answer -imatch "^[ABCDEFGHIJX]$" ) {
			    $valid_answer="true"
			}
		}
		catch {
			$valid_answer="false"
		}
		
		if ($valid_answer.equals("false")) {
			Write-host -ForegroundColor "red" "Please enter a vaild choise from the list above !"
		}	
	}
	until ($valid_answer.equals("true"))

	# call the option
	switch ($answer) {
		"A" {
			local-createPrivCert
		}
		"B" {
			local-exportCert 
		}
		"C" {
			local-importCert 
		}
		"D" {
			local-showCert
		}
		"E" {
			local-signScripts
		}
		"F" {
			 local-showSecSettings
		}
		"G" {
			local-setSecSettings
		}
		"I" {
			local-resetSecSettings
		}
		"J" {
			local-removeSignature
		}
		"X" {
			local-print  -Text "Info -- Exit"
		}
		default {
			local-print  -Text "Info -- Option $answer ???? "
		}
	} 
	
}
else{
	local-print -ForegroundColor "red"  -Text "--------------------------------------------------------------------"
	local-print -ForegroundColor "red"  -Text "You must start a administrative session to deal with certificates"
	local-print -ForegroundColor "red"  -Text "--------------------------------------------------------------------"
}
#==============================================================================



