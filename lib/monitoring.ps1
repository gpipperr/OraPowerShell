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
			local-print  -Text		($gline -f $free.DeviceID,($free.FreeSpace/1GB),($free.Size/1GB),$per_free)
		}		
	}
}

#==============================================================================
#local-get-file_from_postion
# read a file from a byte position
##

function local-get-file_from_postion{
	param (
		  [String]   $filename
		, [int]      $byte_pos 
		, [String[]] $search_pattern
		, [String]   $log_file 
		, [int]      $print_lines_after_match = 0 
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
			$sreader= New-Object System.IO.StreamReader($filename)
			local-print  -Text "Info -- read file", $filename, "size byte::",$filesize,"from postion::",$byte_pos,"writing",$print_lines_after_match," lines after finding"
		
	
			# set the file pointer to the last postion
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
			
			do {
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
				$last_byte_pos=$last_byte_pos+$fline.length
				 	
				
				# only debug
				# local-print  -Text ( "Info -- read line {0,3}  : {1}" -f $counter,$fline )
				
				## search in the line
				# if Match is one line before
				
				if ($after_match -gt 0 ) {
					# debug 
					# local-print  -Text "Info -- after_match feature postion::",$after_match
					$log_line=("{0,20} -> {1} " -f " ",$fline )
					$aline+=$log_line
					$after_match--;					
				}
				else {
					foreach ($spat in $search_pattern){
						if ($fline	-imatch $spat ) {
							# if byte pos is 0 - read from start of file - we can use the line nummber
							if ($byte_pos -eq 0) {
								$log_line=("{0,20}:: Line {1,6} - Match [{2,15}]  : {3}" -f $filename_only,$counter,$spat,$fline )
							}
							# if byte pos is > 0 - read from a byte pos inside the file - output byte position
							else {
								$log_line=("{0,20}:: Byte {1,12} - Match [{2,15}] : {3}" -f $filename_only,$last_byte_pos,$spat,$fline )
							}
							$aline+=$log_line		
							
							# set the the defiend default:
							$after_match=$print_lines_after_match
							# debug 
							# local-print -text "Info -- set after match to::",$after_match
														
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
			local-print  -Text "Info -- add check summery to the satus logfile:",$log_file
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
			}
		}
		
		return $last_byte_pos
	}
	else {
		local-print  -ErrorText "Error -- File $filename not found"
		return 0
	
	}	
	<#
		.EXAMPLE
		local-get-file_from_postion -filename "D:\OraPowerShellCodePlex\log\DB_BACKUP_5.log" 10 ("Warning","RMAN-0") "D:\OraPowerShellCodePlex\log\status_mail.log"
		local-get-file_from_postion -filename "D:\OraPowerShellCodePlex\test\test_pattern_match.txt" 0 (local-get-oracle-error-pattern) "D:\OraPowerShellCodePlex\test\pattern_match.log" -print_lines_after_match 5
		
	#>
}
#==============================================================================
#  local-get-oracle-error-pattern
#  return a array of oracle default error search pattern
##

function local-get-oracle-error-pattern{
	
	[String[]] $error_pattern=@()
	

	
	#NLS Errors
	$error_pattern+="TNS-121[0-9][0-9]"
	$error_pattern+="TNS-12545"
	
	# Oracle internal Errors (idea of list from nagios oracle.cfg, but list fixed with oracle documentation
	# see  http://docs.oracle.com/cd/E18283_01/server.112/e17766/toc.htm

	$error_pattern+="ORA-0020[0-9]" 	# controlfile Errors
	$error_pattern+="ORA-00210" 		# cannot open control file

	$error_pattern+="ORA-00257" 		# archiver is stuck
	$error_pattern+="ORA-00333" 		# redo log read error
	$error_pattern+="ORA-00345" 		# redo log write error

	$error_pattern+="ORA-004[4-7][0-9]" # ORA-0440 - ORA-0485 background process failure
	$error_pattern+="ORA-048[0-5]" 
	
	$error_pattern+="ORA-06[0-3][0-9]" 	# ORA-6000 - ORA-0639 internal errors
	$error_pattern+="ORA-6[0-3][0-9]" 	# ORA-6000 - ORA-0639 internal errors
	
	$error_pattern+="ORA-006[0-3][0-9]" # ORA-6000 - ORA-0639 internal errors
	$error_pattern+="ORA-1114" 			# datafile I/O write error

	$error_pattern+="ORA-01115" 	 	# datafile I/O read error
	$error_pattern+="ORA-01116" 	 	# cannot open datafile
	$error_pattern+="ORA-01118" 	 	# cannot add a data file
	$error_pattern+="ORA-01578" 	 	# data block corruption
	$error_pattern+="ORA-01135" 	 	# file accessed for query is offline
	$error_pattern+="ORA-01547" 	 	# tablespace is full
	$error_pattern+="ORA-01555" 		# snapshot too old
	$error_pattern+="ORA-01562"  		# failed to extend rollback segment
	$error_pattern+="ORA-0162[89]"  	# ORA-1628 - ORA-1632 maximum extents exceeded
	$error_pattern+="ORA-0163[0-2]" 
	$error_pattern+="ORA-0165[0-6]"  	# ORA-1650 - ORA-1656 tablespace is full
	$error_pattern+="ORA-04031"			# out of shared memory.
                  
	$error_pattern+="ORA-03113"  		# end of file on communication channel
	$error_pattern+="ORA-06501" 		# PL/SQL internal error 
	
	#RMAN errors
	#http://docs.oracle.com/cd/E18283_01/server.112/e17766/rmanus.htm
	$error_pattern+="RMAN-[0-2]"   # RMAN-00550 to RMAN-20507 
	
	#global
	#General
	$error_pattern+="Error"
	$error_pattern+="idle instance"
	$error_pattern+="fehler"
	$error_pattern+="0x0000"
	
	return $error_pattern
}

#==============================================================================