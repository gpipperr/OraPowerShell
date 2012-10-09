#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
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
#set-alias setdb "$scriptpath\setdb.ps1" -Description "Set the Oracle Enviroment alias"
####

Import-Module "$scriptpath\setdb.psm1"

####
cd $scriptpath
####
# SIG # Begin signature block
# MIIEAwYJKoZIhvcNAQcCoIID9DCCA/ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDE+TaFvJ3YMbAUlxjqzFlLfj
# 7eOgggIdMIICGTCCAYagAwIBAgIQswsffWbgur5FbTmMnxtNqDAJBgUrDgMCHQUA
# MBwxGjAYBgNVBAMTEUxvY2FsIENlcnRpZmljYXRlMB4XDTEyMTAwODE2NDUwMloX
# DTM5MTIzMTIzNTk1OVowGjEYMBYGA1UEAxMPUG93ZXJTaGVsbCBVc2VyMIGfMA0G
# CSqGSIb3DQEBAQUAA4GNADCBiQKBgQC2QvNu1p/Q30P/1MyJAadom1kOQ5r+DSk/
# si6OX1MyZBw7KAo5VJkVFSJUWkGycVWhS5g/vi7GJUfN59nfBsa+BOL2qWbgdUXJ
# kb4QAIFhnjLL3o0vahnFUvNLggU7e2Lb7U1HnXJ162M27piidMneo8iLULFZqbix
# 6SNOFra8zwIDAQABo2YwZDATBgNVHSUEDDAKBggrBgEFBQcDAzBNBgNVHQEERjBE
# gBDVerYLw85OfcC2L05Gi3JRoR4wHDEaMBgGA1UEAxMRTG9jYWwgQ2VydGlmaWNh
# dGWCEN6vlJpqhmiXQJ+5DWLZODswCQYFKw4DAh0FAAOBgQAtqLl71Y/h9pdorhGx
# TaQ+wHgjkBJ7YrVxYphnzdO0rQU8hPVSQr0cH3YX0IpAc7IRsbf3GPPldnAAk+Cs
# qOZ2PZtLDULf/wNhQ37rjfmBNZoHFRzSdaaEb1goFiTjHs4M1JmS3ZA0Uo89lSnA
# fr8wpIA2Al0lRo3Cys1EH4p/qzGCAVAwggFMAgEBMDAwHDEaMBgGA1UEAxMRTG9j
# YWwgQ2VydGlmaWNhdGUCELMLH31m4Lq+RW05jJ8bTagwCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FG8x0d+AROUp+K12iec41tdadsgHMA0GCSqGSIb3DQEBAQUABIGAL4HFpE+eedGH
# XhL09jb2M4a2FDVYm1uw586ZCrVuH00AaBa775qVFATsjZDNzHXbAYGMBGBp+BKw
# 7GzG8d5tC1zlTxPfJHVFsCoFCULMSYL+NQd3S8f/hFmUQU6OX8iv13S4WGxx2jh5
# hRji/T0bQp+U+11gOOWexoxBbpFMioU=
# SIG # End signature block
