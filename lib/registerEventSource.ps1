#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Run this Scripts as administrator to register the event souce in the event log
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

#check on Administator
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
# SIG # Begin signature block
# MIIEAwYJKoZIhvcNAQcCoIID9DCCA/ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmzTbkADmOWyVMjXcbbC1QTBb
# T/qgggIdMIICGTCCAYagAwIBAgIQswsffWbgur5FbTmMnxtNqDAJBgUrDgMCHQUA
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
# FAv26+QhFYj6UKa4T/B4Onc9amTIMA0GCSqGSIb3DQEBAQUABIGATRcseD+vzkNz
# W8/jFfjnn3LOhsNpQTqirQEVl7kXZlT9jiXia3LmoNtFw9T7Eu/rPZ9cG9KvyCDx
# VHIS9x5U+e6V9mvYfOcsOUAT7YFGQu5fnj5LbevAfQZ7vc1VcdzjKvH6xieYOkBi
# hbjx9/7DuyIOpFmh21u8cow13hp+XRk=
# SIG # End signature block
