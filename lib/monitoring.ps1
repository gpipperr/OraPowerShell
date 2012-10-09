#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Library for monitoring a running Oracle system
# Date:   07.September 2012
# Site:   http://orapowershell.codeplex.com
#==============================================================================

<#
 
	.NOTES
		Created: 09.2012 : Gunther Pippèrr (c) http://www.pipperr.de
		Security:
			(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
			To switch it off (as administrator)
			get-Executionpolicy -list
			set-ExecutionPolicy -scope CurrentUser RemoteSigned
	.SYNOPSIS
		Generic functions for monitoring the Oracle Database 
	.DESCRIPTION
		Generic functions for monitoring the Oracle Database 
	.COMPONENT
		Oracle Backup Script
#>


#==============================================================================
# list the free space on all disks
# if 
##

function local-freeSpace {
    
	$gline = "Info -- Drive {0} free: {1,7:n} GB from {2,7:n} GB -- {3:n} % free"
	$bline = "Error -- Drive {0} has only free: {1,7:n} GB from {2,7:n} GB -- only {3:n} % free !"

	$freespace = ( get-WmiObject Win32_logicalDisk )

	foreach ($free in $freespace ) {
	
		try {
			$per_free=$free.FreeSpace/($free.Size/100) 
		}
		catch {
			local-print  -ErrorText "Error -- get the size of disk :",$free.DeviceID
			$per_free=0
		}		
			
		if ( $per_free -lt 10 ) {
			local-print  -ErrorText	($bline -f $free.DeviceID,($free.FreeSpace/1GB),($free.Size/1GB),$per_free)
		}
		else {
			local-print  -Text ($gline -f $free.DeviceID,($free.FreeSpace/1GB),($free.Size/1GB),$per_free)
		}
	}
}

#==============================================================================
#local-get-file_from_position
# read a file from a byte position
##

function local-get-file_from_position{

	<#
	
	.DESCRIPTION
		Anlayse Logfile for Errors with a list af patterns and write the result to a status log
		
	.PARAMETER $filename
		File to analyse
	.PARAMETER $byte_pos 
		Byte Position in the file to start the analyse 0 - From the beginning
	.PARAMETER  $search_pattern
		String arry with the pattern to search
	.PARAMETER $log_file 
		File to write the output (result of the matches)
	.PARAMETER $print_lines_after_match
		If a match occurs print also to the logfile the next x lines
	.PARAMETER $print_lines_before_match 
		If > 0 print ONE! line BEFORE the match 
	.PARAMETER $ignorePat
		Arrray of ingore pattern - If a match occur it will be checked if other word in the line are disable the match
	
	.EXAMPLE
		local-get-file_from_position -filename "D:\OraPowerShellCodePlex\log\DB_BACKUP_5.log" 10 ("Warning","RMAN-0") "D:\OraPowerShellCodePlex\log\status_mail.log"
		local-get-file_from_position -filename "D:\OraPowerShellCodePlex\test\test_pattern_match.txt" 0 (local-get-error-pattern -list "oracle") "D:\OraPowerShellCodePlex\test\pattern_match.log" -print_lines_after_match 5
		
	#>
		
	param (
		  [String]   $filename
		, [int]      $byte_pos 
		, [String[]] $search_pattern
		, [String]   $log_file 
		, [int]      $print_lines_after_match = 0 
		, [int]      $print_lines_before_match = 0
		, [String[]] $ignorePat = ("Insgesamt","Extras")
	)
	
	$filename_only=split-path -Leaf $filename
	
	if (Get-ChildItem $filename -ErrorAction silentlycontinue) {
	
		try {
			
			$filesize= (Get-ChildItem $filename).length
			
			if ( $filesize -lt $byte_pos) {
				local-print  -Text  "Filessize :: $filesize is smaller then position in byte :: $byte_pos from file  $filename - start form the 1. byte of the file"
				$byte_pos=0;
			}
			
	
			# Open Streamreader to read the file
			# see http://msdn.microsoft.com/de-de/library/system.io.streamreader%28v=vs.80%29.aspx
			#
			local-print  -Text "Info -- read file", $filename, "size byte::",$filesize,"from position::",$byte_pos,"writing",$print_lines_after_match," lines after finding"
			$sreader= New-Object System.IO.StreamReader($filename)

			# set the file pointer to the last position
			$last_byte_pos = $byte_pos
			$sreader.BaseStream.Position = $byte_pos

			# read in array
			$aline=@()
			[String] $fline="-"
			[int] $counter=0;

			#Debug
			#local-print  -Text "Info -- check logfile::",$filename_only," for pattern::",$search_pattern

			# print also lines after a match 
			$after_match=0;
			
			$line_before_match="-"

			do {
				#remember the line before
				if ($fline) { $line_before_match=$fline}
				# read one line
				$fline=$sreader.ReadLine()
				$counter++
				
				# check if the line is empty (reader not at the end of the file!)
				if ( -not $fline) {
					# the on end of file
					if ( -not ( $sreader.EndOfStream) ){
						$fline=" "
					}
				}
				# fix byte to char !!! 
				# $sreader.BaseStream.Position ?? shows only x*1024 ??
				#[System.Text.Encoding]::Unicode.GetByteCount($s)   ??
				$last_byte_before_pos=$last_byte_pos
				$last_byte_pos=$last_byte_pos+$fline.length

				# only debug
				# local-print  -Text ( "Info -- read line {0,3}  : {1}" -f $counter,$fline )

				## search in the line
				# if Match is one line before

				if ($after_match -gt 0 ) {
					# debug 
					# local-print  -Text "Info -- after_match feature position::",$after_match
					$log_line=("{0,20} -> {1} " -f " ",$fline )
					$aline+=$log_line
					$after_match--;
				}
				else {
					$print_line=$true
					foreach ($spat in $search_pattern){
							if ($fline	-imatch $spat ) {
							$print_line=$true
							# if match , use the ignore list to filter false results
							foreach ($ipat in $ignorePat){
								if ( $fline -imatch $ipat) {
									$print_line=$false
								}
							}
							if ($print_line){
								# if byte pos is 0 - read from start of file - we can use the line nummber
								if ($byte_pos -eq 0) {
									
									# print the one line before the match
									if ($print_lines_before_match -gt 0) {
										$log_line=("{0,20}:: Line {1,6} - Match [{2,15}]  : {3}" -f $filename_only,($counter-1),$spat,$line_before_match )
										$aline+=$log_line
									}
									
									$log_line=("{0,20}:: Line {1,6} - Match [{2,15}]  : {3}" -f $filename_only,$counter,$spat,$fline )
								}
								# if byte pos is > 0 - read from a byte pos inside the file - output byte position
								else {
									
									# print the one line before the match
									if ($print_lines_before_match -gt 0) {
										$log_line=("{0,20}:: Byte {1,12} - Match [{2,15}] : {3}" -f $filename_only,$last_byte_before_pos,$spat,$line_before_match )
										$aline+=$log_line
									}
									
									$log_line=("{0,20}:: Byte {1,12} - Match [{2,15}] : {3}" -f $filename_only,$last_byte_pos,$spat,$fline )
								}
								$aline+=$log_line
								
								# set the the defiend default:
								$after_match=$print_lines_after_match
								# debug 
								# local-print -text "Info -- set after match to::",$after_match
							}
							# exit after the first match
							break
						}
					}
				}
				
			}
			until ((-not ($fline)) )
			
			# write to log file
			if ( (-not $aline) -or ( $aline.length -eq 0) ) {
				$aline+=("{0,20}:: Byte Position {1,12} : {2} Nothing from interest found - last check {3:d}" -f $filename_only,$last_byte_pos,$fline,(get-date))
			}
			
			$aline+="============================================================================="			

			# write the result to the summary log

			if ($log_file) {
				add-content $log_file ("============================{0,20}==============================="	-f $filename_only) 
				add-content $log_file $aline
			}
			else {
				local-print  -ErrorText "Error -- No status file defined"
			}
			#
				
			
		}
		catch {	
			
			local-print  -ErrorText "Error -- Error ::",$_
		}
		finally {
			if ($sreader) {
				$sreader.close();
				local-print  -Text "Info -- add check summery to the status logfile:",$log_file
			}
		}
		
		return $last_byte_pos
	}
	else {
		local-print  -ErrorText "Error -- File $filename not found"
		return 0
	}
	
}
#==============================================================================
#  local-get-error-pattern
#  return a array of oracle default error search pattern
##

function local-get-error-pattern{

param (
	[String] $list = "oracle" 
)
	[String[]] $error_pattern=@()
	
	# read pattern definition
	try {
		$pattern_path="$scriptpath\conf\search_pattern.xml"
		$pattern_list= [xml] ( get-content $pattern_path)
		
		if ("oracle".equals($list)) {
		
			# read the pattern into the array
			foreach ($pat in $pattern_list.search_pattern.oracle.error_pattern ) {
				$error_pattern+=$pat.toString()
			}
		}
		else {
			# read the pattern into the array
			foreach ($pat in $pattern_list.search_pattern.other.error_pattern ) {
				$error_pattern+=$pat.toString()
			}		
		}
	} 
	catch {
		local-print  -ErrorText "Error -- Pattern definition $pattern_path hast errors",$_
		
		if ("oracle".equals($list)) {
			$error_pattern+="error"
			$error_pattern+="fehler"
			$error_pattern+="ORA-"
			$error_pattern+="RMAN-"
			$error_pattern+="TNS-"
			$error_pattern+="idle instance"
		}
		else {
			$error_pattern+="error"
			$error_pattern+="fehler"
			$error_pattern+="kann nicht"
			$error_pattern+="can not"
			$error_pattern+="result"
			$error_pattern+="warning"
		}
		
		local-print  -ErrorText "Error -- Using default list ",$error_pattern
	}

	return $error_pattern
}


#==============================================================================
#  local-get-oracle-error-pattern
#  return a array of oracle default error search pattern
##


function local-send-status-file {
	param (
		 $smtpServer 
		,$port
		,$to
		,$from
		,$status_file
		,$username
		,$password	
	)
	
	# check the parameter
	try{
		# check the file name with the mail text
		if (-not (Get-ChildItem $status_file -ErrorAction silentlycontinue) ){
			local-print  -ErrorText "Error --  the text of the e-mail NOT exists: $status_file"
			throw "File $status_file  not exist!"
		}
		else {
			local-print  -Text "Info -- the text of the e-mail exists: $status_file"
		}
		
		# check the name resolution
		$ip=local-get-IpAdress -hostname $smtpServer 
		local-print  -Text "Info -- the hostname of the smtpServer $smtpServer can be resolved to the IP adress::$ip"
		
		# check if the connect to the port is possilbe
		# see http://www.toms-blog.com/powershell-emulate-telnet-session-and-test-output/
		$socket = new-object System.Net.Sockets.TcpClient($smtpServer , $port)  
		if($socket -eq $null) {  
			throw "Can not connect to the smtpServer $smtpServer on port $port"
		}
		else {
			local-print  -Text "Info -- Smtp Connect to the smtpServer $smtpServer estabisched on port::$port"
		}	
		$socket.close()	
	}
	catch {
		local-print  -ErrorText "Error --",$_
		throw $_
	}
	
	
	try {
		#http://technet.microsoft.com/de-de/library/dd347693.aspx
		#
		# Send-MailMessage -to $to -from $from -subject "Daily Status file from" -Attachment (local-get-statusfile) -smtpServer $smtpServer -credential $credential
		# cause Error see catch block
		
		# Use step by step 
		
		#.Net Object
		$mail = New-Object System.Net.Mail.MailMessage
	 
		# Sender Address
		$mail.From = $from;
	 
		# Recipient Address
		$mail.To.Add($to);
	 
		# Message Subject
		$hostname=@( hostname )
		$mail.Subject = ( "Host::{0} Status from ::{1:d}" -f $hostname,(get-date))
	 
		# Message Body
		# read content from status file
		$mailtext = get-content $status_file
		
		$mail.Body = $mailtext;
		
		# Connect to your mail server
		$smtp = New-Object System.Net.Mail.SmtpClient($smtpServer);
	    
		# only if nessesary
		if ($username) {
			$smtp.Credentials = New-Object System.Net.NetworkCredential($username, $password);
		}
	 
		# Send Email
		$smtp.Send($mail);
		
	
	}
	catch {

		$error_txt+=@()
		
		$error_txt+=($error[0].Exception | fl * -force)
		
		local-print -ErrorText "Error --",  $error_txt
		
		$error_txt=("-"*40)+$CLRF
		
		local-print -ErrorText "Error --",  $error_txt
		
		$error_txt=" If you get this Error :"+$CLRF
		$error_txt+=" Ausnahme beim Aufrufen von Send mit 1 Argument(en):  Postfach nicht verfügbar. Die Serverantwort war: Please use a fully-qualified domain name for HELO/EHLO"+$CLRF
		local-print -ErrorText "Error --",  $error_txt
		
		$error_txt=" check for this possible reason"+$CLRF
		$error_txt+=" The current implementation of the System.Net.Mail.SmtpClient uses the NetBIOS name of the computer in the HELO / EHLO  commands."+$CLRF
		$error_txt+=" Many anti-spam systems require the FQDN instead. As a result, email  sent with the SmtpClient class is often blocked."+$CLRF
		$error_txt+=" see http://social.msdn.microsoft.com/forums/en-US/netfxnetcom/thread/77f45c5f-76be-400c-a529-a1e49d6d8e62/"+$CLRF
		$error_txt+=" Hotfix"+$CLRF
		$error_txt+=" http://support.microsoft.com/kb/957497"+$CLRF
		
		local-print -ErrorText "Error --",  $error_txt
	}
	finally {
		# close the connection
		#$smtp.Dispose()
	}
	
	
	<#
		.Example
			$smtpServer = "smtp.pipperr.de"
			$to			= "gunther@pipperr.de"
			$from		= "gunther@pipperr.de"
			$port		= 25
			$username	= "gunther@pipperr.de"
			$status_file= "D:\OraPowerShellCodePlex\log\STATUS.txt"
			$password	= Read-Host "Mail-Password:"
			
			local-send-status-file -smtpServer $smtpServer -port $port -to $to -from $from -status_file $status_file -username $username -password $password
	
	#>
}

#==============================================================================
# local-get-IpAdress
# get the first IP Adress of a hostname
#
##
function local-get-IpAdress {
	param (
	$hostname
	)
	
	try {
		#http://msdn.microsoft.com/de-de/library/system.net.dns.aspx
		$resolf=[System.Net.Dns]::GetHostAddresses($hostname)
		return $resolf[0].IPAddressToString
	} 
	catch {
		local-print  -ErrorText "Error --",$S_
		throw "Can not resolve the $hostname"
	}
}

#==============================================================================
# local-send-status
# send the status via e-mail
#
##
function local-send-status {
	param ( 
			$mailconfig 
		, 	$log_file 
	)
		
	if  ("true".equals($mailconfig.mail.use_mail.toString()) ) {

		# Server
		$smtpServer = $mailconfig.mail.smtpServer.toString()
		$port		= $mailconfig.mail.port.toString()
			
		# user
		if ("true".equals($mailconfig.mail.use_credential.toString()) ) {
			
			$lepassword = ($mailconfig.mail.username).GetAttribute("password") 
			$password = local-read-secureString -text $lepassword
			$username  = $mailconfig.mail.username.InnerText
		}
		else {
	       local-print -Text "Warning -- try to send mail without credentials"  -ForegroundColor "yellow" 	
		}
		
		# Mail
		$to			= $mailconfig.mail.to.toString()
		$from		= $mailconfig.mail.from.toString()		
			
		local-print -Text "Info -- Send the status mail with:  -smtpServer $smtpServer -port $port -to $to -from $from -status_file $log_file  -username $username -password xxxxx"
				
		if ("true".equals( $mailconfig.mail.smpt_server_needs_fqdn.toString())) {
			local-print -Text "Warning -- Sending e-mail via telnet not jet implemented"  -ForegroundColor "yellow"
		}
		else {
			# use the .net classes to send the e-mail
			local-send-status-file -smtpServer $smtpServer -port $port -to $to -from $from -status_file $log_file  -username $username -password $password
		}
	}
	else {
		local-print -Text "Warning -- Sending status report via E-Mail is not configured"  -ForegroundColor "yellow"
	}
}

#============================= End of File ====================================



