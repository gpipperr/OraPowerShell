#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Oracle Connection with .Net DLL
# Date:   01.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================
<#
	.NOTES
		Created: 08.2012 : Gunther Pippèrr (c) http://www.pipperr.de
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
	 
	#Dataset mit dem Ergebniss der SQL Abfrage "füllen"
	
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
