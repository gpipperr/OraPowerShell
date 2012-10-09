#==============================================================================
# Author: Gunther Pipp�rr ( http://www.pipperr.de )
# Desc:   Oracle Connection with .Net DLL
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================
<#
	.NOTES
		Created: 08.2012 : Gunther Pipp�rr (c) http://www.pipperr.de
		Security:
		(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
		To switch it off (as administrator)
		get-Executionpolicy -list
		set-ExecutionPolicy -scope CurrentUser RemoteSigned
		or
		sign scripts!
	.SYNOPSIS
		.net connection to the database - helper funktions
		
	.DESCRIPTION
		.net connection to the database - helper funktions
		
	.COMPONENT
		Oracle Backup Script

#>
#==============================================================================
# set dot.net enviroment 
#
####
#
# !! think on the powershell behavior to return ANY Object from a function  !!
# the first Object is the Reflection.Assembly the second the oracle Object !!
# to use the [1]! as result
#
#
function db_load_dll{
	Param (
		 $dll_path = "d:\oracle\product\11.2.0.3\client_64bit\odp.net\bin\2.x\Oracle.DataAccess.dll"
	)
	# Try to load the DDL for the Oracle Connection
	try{
		local-print  -Text "Info -- try to load the .Net dll from ::",$dll_path
		# DLL load
		[Reflection.Assembly]::LoadFile($dll_path) 
	} 
	catch {
		local-print  -ErrorText "Error -- try to load the .Net dll from ::",$dll_path,"failed"
		throw "try to load the .Net dll from::$dll_path failed"
	}
	
	return New-Object -TypeName Oracle.DataAccess.Client.OracleConnection
}


#==============================================================================
# connect to the database
# Return the DB Connection Object
# 
# $handle=db_load_dll
# $handle=$handle[1]
# $connect=db_connect -user "scott" -password "tiger" -tns_alias "GPI" -OracleConnection $handle
#
####

function db_connect{
	Param (
	   $user
	 , $password
	 , $tns_alias
	 , [Oracle.DataAccess.Client.OracleConnection]  $OracleConnection
	)
 
	# Connect String 
	$ConnectionString  = "User ID="+$user+";"
	$ConnectionString += "Password="+$password+";"
	$ConnectionString += "Data Source="+$tns_alias+";"
	$ConnectionString += "Persist Security Info=True"
 
	$Log_ConnectionString  = "User ID="+$user+";"
	$Log_ConnectionString += "Password=*******;"
	$Log_ConnectionString += "Data Source="+$tns_alias+";"
	$Log_ConnectionString += "Persist Security Info=True"
  
	#Connect to the Database

	# Set the Connect string
	$OracleConnection.ConnectionString = $ConnectionString
	# Open DB Account
	local-print  -Text "Info -- Open  the DB Connection to::",$Log_ConnectionString
	$OracleConnection.Open()	
}

#==============================================================================
# execute the SQL Command
# db_read_sql -SQLCommand "select * from all_users" -OracleConnection  $handle
##
function db_read_sql {
	param(
		   $SQLCommand
		,  [Oracle.DataAccess.Client.OracleConnection]  $OracleConnection
		,  $result_file = "db_information.csv"
		,  $headerinfo   ="SQL Query"
	)

	#initialise SQL Command
	$OracleCommand = New-Object -TypeName Oracle.DataAccess.Client.OracleCommand
	$OracleCommand.CommandText = $SQLCommand
	$OracleCommand.Connection = $OracleConnection
	 
	# Adapter laden
	$OracleDataAdapter = New-Object -TypeName Oracle.DataAccess.Client.OracleDataAdapter
	$OracleDataAdapter.SelectCommand = $OracleCommand
	 
	#Dataset anlegen
	$DataSet = New-Object -TypeName System.Data.DataSet
	 
	#Dataset mit dem Ergebniss der SQL Abfrage "f�llen"
	
	$OracleDataAdapter.Fill($DataSet) |  out-null
	
	##-------------------------
	## http://msdn.microsoft.com/en-us/library/system.data.oracleclient.oracledatareader.aspx
	
	$reader=$OracleCommand.ExecuteReader()
	
	# Header
	for ($i=0;$i -lt $reader.FieldCount;$i++) {
		# Debug structure of the record
		#Write-Host  "Position ::" $i "::" $reader.GetName($i)"::" $reader.GetDataTypeName($i)
		$header+= $reader.GetName($i) + $sep
	}
	
	$csv=$headerinfo+$CLF
	$csv+=$header+$CLF
	
	$write_count=0
	$columns=$reader.FieldCount
    while ( $reader.read() ) {
		$line=""
		for ($i=0; $i -lt $columns; $i++) {
			$col=""
			if ( $reader.IsDBNull($i) ) {
				$col="null"
			} 
			else {
				$col=$reader.GetValue($i)
			} 
			$line+=$col.toString() + $sep	
		}
		
		# write the result every 1000 lines in the textfile
		$write_count+=1
		if ($write_count -gt 1000) {
			add-Content -Path "$result_file" -value $csv
			$write_count=0
			$csv=$line+$CLF
		} 
		else {
			$csv+=$line+$CLF
		}
		
	}
	
	# write the last results
	# save the generated db Content to disk
	add-Content -Path "$result_file" -value $csv

	##-------------------------
	$csv=""
	$OracleDataAdapter.Dispose()
	$OracleCommand.Dispose()
}

#==============================================================================
# Close the DB Connect 
##
function db_close_connect{
	param (  
		[Oracle.DataAccess.Client.OracleConnection] $OracleConnection
	)
	local-print  -Text "Info -- Close the DB Connection to::",$OracleConnection.DatabaseName
	if ($OracleConnection.state.value__ -eq 0 ) {
		local-print  -Text "Info -- Connection was closed"
	}
	else {
		$OracleConnection.Close()	
		local-print  -Text "Info -- Connection is closed"
	}
}

#============================= End of File ====================================
# SIG # Begin signature block
# MIIEAwYJKoZIhvcNAQcCoIID9DCCA/ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsD9AOEb1edRvYBZcWMyrMNN8
# sD2gggIdMIICGTCCAYagAwIBAgIQswsffWbgur5FbTmMnxtNqDAJBgUrDgMCHQUA
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
# FNxr3pqqYINMQsX0QD0mEMH6Lrw6MA0GCSqGSIb3DQEBAQUABIGAmH9WJvv4qBrl
# sWhNIVitK3oOO8bP6Txhxq9TC+DyiT8P/H+MWx8I7Dmhm0A9zXYlMYBxlTrtYxc6
# YthsqNfcOxBMJgUesWiBUSuEt0UGNz46oy7Y8HOUGBxayU4itCb/k0YjHneFMnuL
# ZYlZTtet1FT6wlWy1nmAjFE4qjofg+0=
# SIG # End signature block
