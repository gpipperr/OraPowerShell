#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Library for the Oracle Data import / Export  scripts
# Date:   01.November 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

<#

	.NOTES
		Created: 11.2012 : Gunther Pippèrr (c) http://www.pipperr.de

		Security:
		(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
		To switch it off (as administrator)
		get-Executionpolicy -list
		set-ExecutionPolicy -scope CurrentUser RemoteSigned
  
	.SYNOPSIS
		Load Excel sheet into the database
		
	.DESCRIPTION
		Loading Excel sheets into the database
		
	.PARAMETER 
		None
		
	.COMPONENT
		Oracle Script Library
		
	.EXAMPLE

#>

# Enviroment
Set-Variable CONFIG_VERSION "0.2" -option constant

$Invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptpath=Split-Path $Invocation.MyCommand.Path

write-host "Info -- start the Script in the path $scriptpath"  -ForegroundColor "green"	

cd  $scriptpath

# Script path
# FIX?
$scriptpath=get-location

#==============================================================================

$config_xml="$scriptpath\conf\import_xls_conf.xml"

# read Configuration
$importconfig= [xml] ( get-content $config_xml)

#Check if the XML file has the correct version
if ( $importconfig.import.HasAttribute("version") ) {
	$xml_script_version=$importconfig.import.getAttribute("version")
	if ( $CONFIG_VERSION.equals( $xml_script_version)) {
		write-host "Info -- XML configuration with the right version::  $CONFIG_VERSION "
	}
	else {
		throw "Configuration xml file version is wrong, found: $xml_script_version but need :: $CONFIG_VERSION !"
	}
 }
else {
	throw "Configuration xml file version info missing, please check the xml template from the  new version and add the version attribte to <import> !"
}

# read if exist the mail configuration
$mailconfig_xml="$scriptpath\conf\mail_config.xml"

if (Get-ChildItem $mailconfig_xml -ErrorAction silentlycontinue) {
	$mailconfig = [xml]  ( get-content $mailconfig_xml)
}
else {
	$mailconfig = [xml] "<mail><use_mail>false</use_mail></mail>"
}

#==============================================================================
# read Helper Functions
.  $scriptpath\lib\backuplib.ps1
# load monitoring library
. $scriptpath\lib\monitoring.ps1
# .Net Helper
.  $scriptpath\lib\oracle_dotnet_connect.ps1

################ Semaphore Handling ########################################### 
# Only one script can run at one time

# create named Semaphore
# http://msdn.microsoft.com/de-de/library/kt3k0k2h
# Only on script can run at one time, 1 Resouce possilbe from 1 with the Name ORACLE_IMPORT
$sem = New-Object System.Threading.Semaphore(1, 1, "ORACLE_IMPORT")


#==============================================================================
# log and status file handling
#
# move old log file to .0 
# if log is older then today, if not append
# we have per day one log file from this week and from the last week the .0 logs

$starttime=get-date
# Numeric Day of the week
$day_of_week=[int]$starttime.DayofWeek 


# Default log files for each day of the week
$logfile_name=$scriptpath.path+"\log\DB_IMPORT_"+$day_of_week+".log"
local-set-logfile    -logfile $logfile_name
local-clear-logfile -log_file $logfile_name

# Status Log file
$logstatusfile_name=$scriptpath.path+"\log\STATUS.txt"
local-set-statusfile -statusfile $logstatusfile_name
local-clear-logfile  -log_file  (local-get-statusfile)

#==============================================================================
# Check for unencrypted passwords
local-print  -Text "Info -- Check for unencrypted passwords"

# encrypt the password and change the xml config
$result=local-encryptXMLPassword $importconfig

# Store Configuration (needed if passwort was not encrypted!)
if ($result.equals(1)) { 
    local-print  -Text "Info -- Save XML Configuration with encrypted password"
	$importconfig.Save("$config_xml")
}
else {
	local-print  -Text "Info -- XML Import Configuration not changed - all passwords encrypted"
}

# check for password in the mail_xml

# encrypt the password and change the xml config
$result=local-encryptXMLPassword $mailconfig

# Store Configuration (needed if passwort was not encrypted!)
if ($result.equals(1)) { 
    local-print  -Text "Info -- Save XML Configuration with encrypted password"
	$mailconfig.Save("$mailconfig_xml")
}
else {
	local-print  -Text "Info -- XML Configuration for E-mail Transport not changed - all passwords encrypted"
}



#==============================================================================
#
# read xls files without excel on the system
# 
<#

If there is no execl on the system you can use the Microsoft.ACE.OLEDB.12.0 Provider, works best if you can use the same bit version!


# http://www.microsoft.com/en-us/download/details.aspx?id=13255
# download Bit Version thats fits to your office (32!)
#Wenn Sie als Anwendungsentwickler über ODBC eine Verbindung mit Microsoft Office Excel-Daten herstellen möchten, legen Sie die Verbindungszeichenfolge auf "Driver={Microsoft Excel-Treiber (*.xls, *.xlsx, *.xlsm, *.xlsb)};DBQ=Pfad zur XLS-/XLSX-/XLSM-/XLSB-Datei" fest. 
#Wenn Sie Anwendungen mit OLEDB entwickeln, legen Sie das Anbieter-Argument der Verbindungszeichenfolge-Eigenschaft auf "Microsoft.ACE.OLEDB.12.0" fest. 
#Wenn Sie eine Verbindung mit Microsoft Office Excel-Daten herstellen, fügen Sie den erweiterten Eigenschaften der Verbindungszeichenfolge "Excel 14.0" hinzu. 


# Code example:

$xlsfile="D:\OraPowerShellCodePlex\test\test_data_set.xlsx"

$OleDbConn     = New-Object "System.Data.OleDb.OleDbConnection"
$OleDbCmd      = New-Object "System.Data.OleDb.OleDbCommand"
$OleDbAdapter  = New-Object "System.Data.OleDb.OleDbDataAdapter"
$DataTable     = New-Object "System.Data.DataTable"
  
$OleDbConn.ConnectionString = ("Provider=Microsoft.ACE.OLEDB.12.0;Data Source="+$xlsfile+";Extended Properties=""Excel 12.0 Xml;HDR=YES"";")

$OleDbConn.Open()
 
$OleDbCmd.Connection = $OleDbConn
$OleDbCmd.commandtext = "Select * from [Tabelle1$]"
$OleDbAdapter.SelectCommand = $OleDbCmd
 
$RowsReturned = $OleDbAdapter.Fill($DataTable)
 
ForEach ($DataRec in $DataTable) {
	Write-host $DataRec
}
 
$OleDbConn.Close()

#>

#==============================================================================
#  first Version - using installed Excel on the system 
#  if execl exits is easier the the fight wiht the 32/64 bits   Microsoft.ACE.OLEDB.12.0 Provider
#
#
#==============================================================================


#==============================================================================
# relase the com referenzes
# see http://gallery.technet.microsoft.com/office/cc3afe48-e614-474f-809d-6dcf791bd3f4
#
#

function local-Release-comRef  {
	param ($ref)
	
	([System.Runtime.InteropServices.Marshal]::ReleaseComObject( [System.__ComObject]$ref) -gt 0) 
	[System.GC]::Collect() 
	[System.GC]::WaitForPendingFinalizers() 
} 



#==============================================================================
# 
# read the structure of a Excel file
#
#  for debugging 
#  plan : generate the xml structure for the import descrption
#
#


function local-show-structure {
	param ( 
		 $xlsfile 
		,$excelapp
	)
	
	# Open the Workbooks
	$workbook = $excelapp.Workbooks.Open($xlsfile)
	
	#test how many worksheets inside the boook
	$wcount=($workbook.Worksheets  | Measure-Object).count

	for ( $i=1;$i -lt $wcount+1; $i++) {
		
		# Name of the worksheet
		$worksheet=$workbook.Worksheets.item($i)
		Write-host ( "-- Name of the sheet {0} :: {1}"  -f $i,$worksheet.name )
		# first columns of the worksheet
		# top cells of the table, stop if more then one without value
		# sho
		$printout="|"
		$x=1
		$runLoop=$true
		$firstnull=$false
		do{
			$cell=$worksheet.cells.item(1,$x)
			
		
			if ($cell.value() -eq $null ){
				$runLoop=$false
				$printout+=$CLF
			}
			else {
				$printout+=$cell.value()+"|"
			}
			
			$x++
		} 
		while ($runLoop)
		write-host "-- The column list of the file until the first null column ---"
		write-host $printout
		
		## show the first 10 rows in the file
		write-host "-- The first 10 Rows of the excel file ---"
		$column_count=$x-1
		$printout=""
		for ($y=2;$y -lt 11;$y++){
			for ( $x=1;$x -lt $column_count; $x++) {
				$cell=$worksheet.cells.item($y,$x)
				if ($cell.value() -eq $null) {
					$printout+="-"+"|"
				}
				else {
					$printout+=$cell.value().ToString()+"|"
				}
			}
			$printout+=$CLF	
		}
	
		write-host $printout
	
	}
	  

 
}

#==============================================================================
#
#
#

function local-import-excel {
	param (
		  $config
		 ,[Oracle.DataAccess.Client.OracleConnection] $OracleConnection
		 ,$excelapp
	)
	
	$starttime=get-date
	
	# Numeric Day of the week
	$day_of_week=[int]$starttime.DayofWeek 
	$job_name=$import_process.job_description.ToString()
	local-print  -Text "Info -- Start Import of ::", $job_name ,"at::", $starttime ," Day of Week::" ,$day_of_week  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Start Import of ::", $job_name ,"at::", $starttime ," Day of Week::" ,$day_of_week

	# File
	$xlsfile=$config.file_location.ToString()
	# Worksheet number
	# need as int - if string the .item methode throws error because the wrong index data type!
	[int]$wksnumber=$config.worksheet_number.ToString()
	
	# Open the Workbooks
	local-print  -Text "Info -- open xls file::$xlsfile"
	$workbook = $excelapp.Workbooks.Open($xlsfile)
	
	# read the worksheet
	# test how many worksheets inside the boook
	$wcount=($workbook.Worksheets  | Measure-Object).count
	local-print  -Text ("Info -- read the worksheet {0} from {1} existing worksheets" -f $wksnumber,$wcount)
	$worksheet=$workbook.Worksheets.item($wksnumber)
	local-print  -Text ( "Info -- Name of the worksheet {0} :: {1}"  -f $wksnumber,$worksheet.name )
	
	
	# read job description 
	# arry for all tablenames in the column description
	# hashlist
	$tab_hash=@{}
	# array to hold all information in a array objects
	$imp_row=@()
	
	# check if the tablestructure in the database fits to the configuration
	foreach ( $row_description in $config.row_description ) {
		# get all import tables
		# get the column of the tables
		foreach ($icolumn in $row_description.column) {
				
			#--
			$excel_col=$icolumn.name.toString()
			if ($excel_col -eq $null) { $excel_col="--" }
			
			#--
			$excel_pos=$icolumn.position.InnerText
			if ($excel_pos -eq $null) { $excel_pos=$icolumn.position.toString() }
			if ($excel_pos -eq $null) { $excel_pos="--" }
			
			#--
			$trans_rule=$icolumn.transform_rule.InnerText
			if ($trans_rule -eq $null) { $trans_rule=$icolumn.transform_rule.toString() }
			if ($trans_rule -eq $null) { $trans_rule="--" }
			
			#--
			$tab_name=$icolumn.tablename.toString()
			if ($tab_name -eq $null)  { $tab_name="--" }
			
			#--
			$col_name=$icolumn.tab_column.toString()
			if ($col_name -eq $null)  { $col_name="--" }
			
			# object to store the information
			$imp_col = new-object psobject
			$imp_col | add-member noteproperty excel_colname  ($excel_col)
			$imp_col | add-member noteproperty excel_position ($excel_pos)
			$imp_col | add-member noteproperty transform_rule ($trans_rule)
			$imp_col | add-member noteproperty db_tablename   ($tab_name)
			$imp_col | add-member noteproperty db_tab_column  ($col_name)
			
			# Hashtable to test the DB structure
			[array] $tab_hash["$tab_name"]+=$col_name
			# store the metainformation for the import process
			$imp_row+=$imp_col 
		}
	}
	
	# read the database 
	foreach ( $key in $tab_hash.keys) {
		local-print  -Text "Info -- check database and columns with a test query for table::$key with the columns::",$tab_hash[$key]
		$test_sql="select "
		foreach ( $a in $tab_hash[$key] ) {
			$test_sql+=$a+","
		}
		$test_sql+="1 from "+$key+" where 1=2"
		# test the sql statement
		try{
			local-test-oracle-sql  -SQLCommand $test_sql -OracleConnection $OracleConnection
		}
		catch {
			throw "Test SQL was not sucessfull :: $test_sql error:$_"
		}
	}
	
	# read the data from the excel list
	[int] $working_row=$config.row_description.start_row.ToString()
	# count of rows in the excel sheet
	[int] $read_row_count=0
	
	# check the structure of the excel file
	foreach ($imp_col in  $imp_row) {
		
		[int]$x=$imp_col.excel_position
		
		if ( $x -gt 0 ) {
			$cell=$worksheet.cells.item($working_row,$x)
			
			if ($cell.value() -eq $null ){
				throw ( "No data found in the cell {0},row {1}" -f $working_row,$x )
			}
			else {
				local-print  -Text ( "Info -- check the excel worksheet cell {0}, row {1} :: found {2}" -f $working_row,$x,$cell.value() )
				$read_row_count++
			}
		}
		else {
			local-print  -Text ( "Info -- check the excel worksheet found skip value {0} dummy column" -f $x )
		}
	}
	
	#
	
	# write rows to the database
	#http://stackoverflow.com/questions/343299/bulk-insert-to-oracle-using-net
	#http://www.oracle.com/technetwork/issue-archive/2009/09-sep/o59odpnet-085168.html
	#
	#
	#OracleParameter myparam = new OracleParameter();
	#int n;
	#$OracleConnection.CommandText = "INSERT INTO [MyTable] ([MyId]) VALUES(?)";
	#$OracleConnection.Add(myparam);
    #
	#for (n = 0; n < 100000; n ++) {
    #    myparam.Value = n + 1;
    #    mycommand.ExecuteNonQuery();
    #  }
	#
	# commit count
	#
	
	
	#--
	$endtime=get-date
	$duration = [System.Math]::Round(($endtime- $starttime).TotalMinutes,2)
	local-print  -Text "Result -- Finish Import of ::", $job_name ,"at::",  $duration, "Minutes"  -ForegroundColor "yellow"
	local-log-event -logText "Info -- Import of ::", $job_name ,"at::",  $duration, "Minutes"
	local-print  -Text "Info ------------------------------------------------------------------------------------------------------"

}


############################### start Import ##########################################

try{

	local-print  -Text "Info -- Check if other instance of a import script is running (over Semaphore ORACLE_IMPORT)"
	
	#==============================================================================
	# Wait till the semaphore if free
	$wait_on_semaphore=$sem.WaitOne()
	
	#==============================================================================
	# open excel
	# Create the Excel com Object
	$excelapp = New-Object -comobject Excel.Application
	# Make Excel invisible  
	$excelapp.visible = $false

	#==============================================================================
	# check the .net  enviroment and enable the .net class
	#search for the library in the path of dot_net_orcle_home
	
	$dot_net_library=$importconfig.import.db_settings.dot_net_orcle_home.toString()
	
	try {
		$fl=Get-ChildItem $dot_net_library -Recurse -Include "Oracle.DataAccess.dll" -ErrorAction silentlycontinue
		
		if ($fl) {
			if ($fl.count) {
				$dot_net_library=$fl[0].DirectoryName +"\"+ $fl[0].Name
			} 
			else {
				$dot_net_library=$fl.DirectoryName +"\"+ $fl.Name
			}
		}
		# Use .net!
		if (get-item $dot_net_library -ErrorAction silentlycontinue ) {
			$use_dot_net=$true
		}
		else {
			
			$i=$error.count-1
			local-print  -ErrorText "Error --",$error[$i]
			throw "Error -- Dot Net Library Oracle.DataAccess.dll not found!"
		}
	}
	catch {
		local-print  -ErrorText "Error -- Dot Net Library Oracle.DataAccess.dll not found in path (attribute dot_net_orcle_home) ::",$dot_net_library
		throw "Error -- Dot Net Library Oracle.DataAccess.dll not found in path (attribute dot_net_orcle_home) :: $dot_net_library"
	}

	#==============================================================================
	# connect to the database
	# Load the dll
	$handle=local-db_load_dll -dll_path $dot_net_library
	$handle=$handle[1]

	#connect to the DB
	# get user name und tns
	$ltns_alias = $importconfig.import.db_settings.tns_alias.toString()
	$lepassword = ($importconfig.import.db_settings.username).GetAttribute("password") 
	$lepassword = local-read-secureString -text $lepassword
	$lusername  = $importconfig.import.db_settings.username.InnerText

	$connect=local-db_connect -user $lusername -password $lepassword -tns_alias $ltns_alias -OracleConnection $handle

	#==============================================================================
	# read configuration
	foreach ($import_process in $importconfig.import.xls_file) {
		$job_name=$import_process.job_description.ToString()
		local-print  -Text "Info -- Start the import of the job::",$job_name
		
		$xlsfile=$import_process.file_location.ToString()
	
	
		#check if file extis
		if (Get-ChildItem $xlsfile -ErrorAction silentlycontinue) {
		
			local-print  -Text "Info -- import the file ::",$xlsfile
		
			# test case to check the structure 
			# only debug
			#local-show-structure -xlsfile $xlsfile  -excelapp $excelapp
		
			# start the import routine
			local-import-excel -config $import_process -OracleConnection $handle -excelapp $excelapp
		
		}
		else {
			local-print  -ErrorText "Info -- the file :: $xlsfile not exits - nothing imported - check your configuration!"
		}
	}
} 
catch {
	#  Error Details:
	#  $error[0].Exception | fl * -force
	#
	local-print -Text "Error -- Failed to import: The error was: $_." -ForegroundColor "red"
	local-log-event -logtype "Error" -logText "Error- -- Failed to import: The error was: $_."
}
finally {
		#==============================================================================
		# close the datbase
		# 
		local-db_close_connect -OracleConnection  $handle
	
		#==============================================================================
		# exit excel
		$excelapp.Quit() 
		# free resources 
		$x=local-Release-comRef -ref $excelapp

		#==============================================================================
		# Exit the semaphore
		local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
		local-print  -Text "Info -- release  the Semaphore ORACLE_IMPORT"
		try {
			$sem.Release() |  out-null
		}
		catch {
			local-print -Text "Error -- Faild to release  the emaphore ORALCE_IMPORT - not set or Import not started? Error:$_" -ForegroundColor "red"
		}
		local-print  -Text "Info ------------------------------------------------------------------------------------------------------"
		#==============================================================================

		#==============================================================================
		# Check the logfiles and create summary text for check mail
		
		$last_byte_pos=local-get-file_from_position -filename (local-get-logfile) -byte_pos 0 -search_pattern (local-get-error-pattern -list "oracle") -log_file (local-get-statusfile)
		# send the result of the check to a mail reciptant 
		# only if configured!
		local-send-status -mailconfig $mailconfig -log_file (local-get-statusfile)
		
		#==============================================================================

}

#============================= End of File ====================================

