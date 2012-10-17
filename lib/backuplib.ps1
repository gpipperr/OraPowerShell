#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Library for the backup scripts
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
	.SYNOPSIS
		Generic functions for backup
	.DESCRIPTION
		Generic functions for backup
	.COMPONENT
		Oracle Backup Script
#>

## global PARAMETER
Set-Variable CLF "`r`n" -option constant

# create with the option AllScpe to hava a global variable!

Set-Variable backup_logfile 	"DB_BACKUP" -option AllScope
Set-Variable backup_statusfile 	"STATUS.TXT" -option AllScope

#==============================================================================
# get the location of the log file
##

function local-get-logfile {
	return $backup_logfile
}
function local-set-logfile {
	param(
		$logfile
	)
	$backup_logfile=$logfile
	write-host ("Info -- Use log file Name ::{0}" -f (local-get-logfile) )  -ForegroundColor "green"
}

#==============================================================================
# get the location of the status log file
##

function local-get-statusfile {
	return $backup_statusfile
}

function local-set-statusfile {
	param(
		$statusfile
	)
	
	$backup_statusfile=$statusfile
	write-host ("Info -- Use Status summary log ::{0}" -f (local-get-statusfile) )  -ForegroundColor "green" 
}

#==============================================================================
# get the name of the eventlog
# possible envent logs Get-EventLog -list
##
function local-get-eventlog-name {
	return "Application"
}

#==============================================================================
# get the name of log source for the event log
##
function local-get-eventlog-source {
	return "ORA_BACKUP"
}

#==============================================================================
# clear log file
##
function local-clear-logfile {
	param (
		$log_file
	)
	$today=(get-date).date
	$log_file_name = split-path $log_file -Leaf
	
	# check if file exists
	if ( Test-Path $log_file ) {
		# check if file is from today - append 
		$file_age=Get-Item  $log_file | select LastWriteTime
	  	if ($file_age.LastWriteTime -gt $today ){
			local-print -text "Info -- Append to file $log_file_name -- file last access::",$file_age.LastWriteTime,"Today::",$today
		}
		else { 
			cp "$log_file" "$log_file.0"
			rm "$log_file"
			local-print -text "Info -- remove old logfile",$log_file
		}
	}
	else {
		local-print -text "Info -- file $log_file_name not exists"
	}
}

#==============================================================================
# Helper Funktion to write log file and display message
##
function local-print{
	# Parametes
	Param( 
		  [String]   $ForegroundColor = 'White'
		, [String[]] $text 
		, [String[]] $errortext
	)
	# End param
	Begin {}
	Process {
		$backup_log = local-get-logfile 
		# Message for the log
		if ($errortext){
			$text=$errortext 
			$ForegroundColor = "red"
		}
		$log_message = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") +":: " +$text 
		try {
			write-host -ForegroundColor $ForegroundColor $text  
			 # check if the file is accesible
			 try{
				$log_message  | Out-File -FilePath "$backup_log" -Append
			 }
			 catch {
			    write-host -ForegroundColor "red" "Error -- Logfile not accessible see text above"
			 }
		} 
		catch {
				throw "Error -- Failed to create log entry in: $backup_log. The error was: $_."
		}
	}
	
	End {}
}

#==============================================================================
# if you like to log to the eventlog you have to register the event id
# This must be done as Administrator!
# http://msdn.microsoft.com/de-de/library/system.diagnostics.eventlog.aspx
#
###
function local-register-eventlog {

	$log_source=local-get-eventlog-source
	$event_log=local-get-eventlog-name
	
	local-print -text "Info-- Try to register Event Source::",$log_source,"Event log::",$event_log
	if(![system.Diagnostics.EventLog]::SourceExists($log_source,".")){ 
		#Here we need Admin rights!!!!!!
		$strLog = [system.Diagnostics.EventLog]::CreateEventSource($log_source,$event_log)
		local-print -text "Info --  Event Source::",$log_source,"Event log::",$event_log,"registered"
	}
	else {
	 local-print -text "Info --Event Source::",$log_source,"Event log::",$event_log,"still registered"
	}
}
#==============================================================================
# deregister the eventlog Source
#  to delete a custom event log use  [system.Diagnostics.EventLog]::Delete("Anwendung")
####
function local-deregister-eventlog {
	$log_source=local-get-eventlog-source
	$event_log=local-get-eventlog-name
	
	local-print -text "Info -- Try to deregister Event Source::",$log_source,"Event log::",$event_log
	
	if([system.Diagnostics.EventLog]::SourceExists($log_source,".")){ 
        [system.Diagnostics.EventLog]::DeleteEventSource($log_source);  
		local-print -text "Info --  Event Source::",$log_source," for Event log::",$event_log,"deregistered"
	}
	else {
		local-print -text "Error --  Event Source::",$log_source," for Event log::",$event_log,"not exits"
	}
}

#==============================================================================
# write to the eventlog
#  to register the event source !!
# all types with [Enum]::GetValues([System.Diagnostics.EventLogEntryType])
# one type [System.Diagnostics.EventLogEntryType]::Information 
##
function local-log-event { 
	param( 
		  [string]$logText
		, [string]$logtype = "Information "
	 ) 
	
	#Name of the event source
	$log_source=local-get-eventlog-source
	#Name of the event log
	$event_log=local-get-eventlog-name
	try {	
		# check if the eventsource exists, if not create the source!
		if([system.Diagnostics.EventLog]::SourceExists($log_source,".")){ 
			#
			$log = New-Object System.Diagnostics.EventLog($event_log,".")
			$log.set_source($log_source) 
			
			# write Log entriy
			$log.WriteEntry($logText,$logtype) 
			$log.Close()
		}
		else {
			local-print -text "Error -- Event Source::",$log_source,"for Event log::",$event_log,"not registered, use local local-register-eventlog as administrtor to enable event logging!"
		}
	}
	catch {
		local-print -text "Error -- Event Source::",$log_source,"for Event log::",$event_log,"not registered, use local-register-eventlog function as administrtor to enable event logging!"
	}
	<#
	.NOTES
		Created: 15.08.2012 : Gunther Pippèrr (c)		
	.SYNOPSIS
		Write logs to the eventlog
	.DESCRIPTION
		Write logs to the eventlog
		This function can only write to the event log if the event source was defined as administator		
	.PARAMETER logtext
		Text to write to the enventlog
	.PARAMETER logtype
		Default "Information" - Possible Values see [Enum]::GetValues([System.Diagnostics.EventLogEntryType])
	.COMPONENT
		Oracle Backup Script
	.EXAMPLE
	  local-log-event -logText "Message" -logType="Error"
	#>
} 


#==============================================================================
# source: http://msdn.microsoft.com/en-us/library/system.runtime.interopservices.marshal.securestringtocotaskmemunicode.aspx
##
function local-read-secureString {
	Param( [String] $text )#end param
	 
	 #String to secure String
	 $stext=ConvertTo-SecureString -String $text
	 #read secure string
     $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($stext)
     $result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
     [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
     ##DEBUG!! write-host "Password decrypted func::"  $result
	 return $result
}


#==============================================================================
# check if a path exists, if not create the path
##

function local-check-dir {
	 Param(
		 [string] $lcheck_path
		,[string] $dir_name
		,[string] $create_dir="true"
	 ) #end param
 
	$check_result="false"

	if ( Test-Path  $lcheck_path) {
	  local-print -ForegroundColor "green"  -Text "Info --", $dir_name, "directory::" , $lcheck_path , "exists"
	  $check_result="true"
	}
	else
	{
		local-print  -ForegroundColor "red"  -Text "Error --" ,$dir_name ,"directory::"  ,$lcheck_path, "not exist"
		$check_result="false"
		if ($create_dir.equals("true")){
			local-print  -Text  "Info -- create" ,$dir_name ,"directory"
			local-print  -Text  " "
			mkdir $lcheck_path
		}
	}
	return 	$check_result	
}	

#==============================================================================
# search in XML the password and decrypt the password
# for this local maschine
# return 0 if nothing has changed
##

function local-encryptXMLPassword {
	Param ( $xmlConfig ) # end Param
	$result=0
    # search in xml for node <username> and iterate over the username
	foreach ($username in select-xml -xml $xmlConfig -XPath //username) {
	    # check if username has password attribute
		if ( ($username).Node.HasAttribute("password")){
		    # only if not jet encrypted
			if ( ($username).Node.GetAttribute("encrypt").equals("false") ) {
				# get clear passwort
				$epassword=($username).Node.GetAttribute("password") 
				# wirte password to secure string
				$sspassword = New-Object System.Security.SecureString
				$epassword.GetEnumerator() | foreach {$sspassword.AppendChar($_)}
				$sspassword.MakeReadOnly()
			    # translate to string
				$epassword=$sspassword|convertFrom-SecureString
				# set the value in the XML
			 	($username).Node.SetAttribute("password",$epassword)	
				($username).Node.SetAttribute("encrypt","true")	
				local-print  -Text "Info -- encrypt Password for user::", ($username).toString()
				$result=1
				
			}
			else {
				local-print  -Text "Info -- check Password :: is encrypted for user::" ,($username).toString()
			}
		}
	}
	return $result
}


#==============================================================================
#Save data over robocopy 

		# Parameter examples
		# /B  		:: Backup mode
		# /S 		:: rekuursive 
		# /COPYALL 	:: COPY ALL file info 	
		# /SEC 		:: copy files with SECurity 
		# /MIR 		:: MIRror a directory tree  
		# /LOG:" +$scriptpath+"\ROBOCOPY_LOG_" +$day_of_week+ ".log "
		# /NFL /NDL /XF ROBOCOPY_LOG_" +$day_of_week+ ".log "
		# /XD 'Recycled' 'System Volume Information' " 
		# /R:n 		:: number of Retries 
		# /W:n 		:: Wait time between retries 
		# /LOG 		:: Output log file 
		# /NFL 		:: No file logging 
		# /NDL 		:: No dir logging 
		# /XF file [file]... :: eXclude Files matching given names/paths/wildcards. 
		# /XD dirs [dirs]... :: eXclude Directories matching given names/paths. 
		# /NP 		:: No percentage
		# FIX
		#/COPYALL  /SEC is not working!
		# FIX
		# use /FFT if you copy on a nas to fix timestamp issues
		
		#default
##

function rcopydata{
		param (
			 [String] $soure_directories
			,[String] $target_directory
			,[String] $roptions
		)
		
	# try to find robo copy
	if (test-path((gc env:systemroot)+"\system32\RoboCopy.exe")) { 
		$robocopy = (gc env:systemroot)+"\system32\RoboCopy.exe" 
	}     
	else { 
		local-print   "Error -- Download a copy of RoboCopy and put in $env:systemroot\system32\" 
		throw "Download a copy of RoboCopy and put in $env:systemroot\system32\" 
	}    
	
	$options=@()
	$options  +="/SD:$soure_directories" + $CRF
	$options  +="/DD:$target_directory"  + $CRF
	
	if ($roptions) {
		# transform to arry
		$options+=$roptions.Split(" ")
	}
	else {
		
		local-print  -Text "Warning -- parameter roptions missing,using defaults" -ForegroundColor "yellow"
		$options  +="/R:0" + $CRF
		$options  +="/W:0" + $CRF
		$options  +="/S"   + $CRF
		$options  +="/NP"  + $CRF
		$options  +="/FFT" + $CRF
	}
	
	# write the options to a command file
	set-content "$scriptpath/generated/generated_robocopy.RCJ" $options
	
    local-print  -Text "Info -- start robocopy with the following command line"
	local-print  -Text "Info --",$options

	# start robocopy to transfer the data
	
	$robo_log=@()

	& $robocopy "/JOB:$scriptpath/generated/generated_robocopy" 2>&1 | foreach-object { local-print -text "ROBOCOPY OUT::",$_.ToString();$robo_log+=$_.ToString()  }

	 local-print  -Text "Result -- robocopy from $soure_directories to $target_directory"
	for ($i=$robo_log.length-7; $i -le ($robo_log.length-3); $i++) {
		 local-print  -Text ( "Result -- Robocopy transfer:: {0}" -f $robo_log[$i] )
	}
	$robo_log=$null
}

#==============================================================================
# check for open file
#
#
	#trap {
	#		Set-Variable -name file_open -value $true -scope 1
	#		#$file_open=$true;	
	#	}
	# test open
	
function local-check-file-open {
	 param(
		[String] $filename 
	 )
	
	$file_open=$false;
	
 	$file_handle= New-Object System.IO.FileInfo $filename
	try {
		$file_stream = $file_handle.Open( [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None )
		# close is successfull
		if ($file_stream) {
			$file_stream.close();
			$file_stream.dispose()
			# wait a short moment that the file is realy closed!
			# reason => execption when after the test remove-item is called with out a short break
			sleep 2
		}
	}
	catch {
		$_
		$file_open=$true;
	}
	return $file_open  
}

#==============================================================================
# get the MD5 Hash of a file
#
# with external tooling
function local-getMD5HashFciv {
	param (
		$file
	)
	
	local-print  -Text "info -- check the integriy of the file::$file"
	
	# check if the fciv exits in Path
	try {
		$md5prog=(fciv)
		# if there no excpetion!
		$md5prog="fciv.exe"
	} 
	catch {
		try {
			# Path to search for the md5 program
			$md5prog_path="C:\Program Files\*"
	
			# search after the cert programm and use the last match
			foreach ( $md5prog in (Get-ChildItem -Recurse -Include "makecert.exe" -Path $md5prog_path ) ) { }
	
			local-print  -Text "info -- use the md5 software from $md5prog"
		}
		catch {
			local-print  -ErrorText "Error - fciv not found in $md5prog_path"
			local-print  -ErrorText ("-"*80)
			local-print  -ErrorText "You can download makecert.exe from http://support.microsoft.com/kb/841290"
			local-print  -ErrorText ("-"*80)	
		}
	}
	$md5output=@()
	& "$md5prog" -md5 $file 2>&1 | foreach-object { local-print -text "MD5 OUT::",$_.ToString();$md5output+=$_.ToString() }
	
	return $md5output[3].toLower().Replace($file.toLower(),"").Trim()
}

# better without external tooling
#
#http://blog.brianhartsock.com/2008/12/13/using-powershell-for-md5-checksums/
#
function local-getMD5Hash {
	param(
		$file
	)
	
	if (get-ChildItem $file -ErrorAction silentlycontinue ) {
 
		$algorithmus = [System.Security.Cryptography.HashAlgorithm]::Create("MD5")
		$stream = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Open)
		
		$md5StringBuilder = New-Object System.Text.StringBuilder
		$algorithmus.ComputeHash($stream) | % { [void] $md5StringBuilder.Append($_.ToString("x2")) }
		
		$stream.close()
		$stream.Dispose()
		
		return $md5StringBuilder.ToString()
	}
	else {
		local-print  -ErrorText "Error -- $file not found"
	}
}


#==============================================================================
# get the MD5 Hash of a file from the MD5 DB XML
#

function local-getDB_MD5Hash {
	param (
		$file
	)
	
	$md5_hash_xml="$scriptpath\conf\md5_hash.xml"
	
	# read Configuration
	$md5db= [xml] ( get-content $md5_hash_xml)
	
	$md5hash="------"
	
	foreach($entry in $md5db.check.file_entry ) {
		if ($entry.name.toString().toLower().equals($file.toLower())){
			$md5hash=$entry.md5.toString()
		}
	}
	
	local-print  -Text "info -- read from md5 db the hash::$md5hash for the file $file"
	
	return $md5hash
}
#============================= End of File ====================================







