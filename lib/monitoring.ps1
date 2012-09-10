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
	)
	
	$filename_only=split-path -Leaf $filename
	
	if (Get-ChildItem $filename -ErrorAction silentlycontinue) {
	
		try {
			
			$filesize= (Get-ChildItem $filename).length
			
			if ( $filesize -lt $byte_pos) {
				throw "Filessize :: $filesize is smaller then position in byte :: $byte_pos from file  $filename"
			}
	
			# Open Streamreader to read the file
			# see http://msdn.microsoft.com/de-de/library/system.io.streamreader%28v=vs.80%29.aspx
			#
			$sreader= New-Object System.IO.StreamReader($filename)
			local-print  -Text "Info - read file", $filename, "size byte::",$filesize
		
			#$filesize - 
			# read all
			#$sreader.BaseStream.Position = ($byte_pos)
			
			# read in array
			$aline=@()
			[String] $fline="-"
			[int] $counter=0;
			
			local-print  -Text "Info -- check logfile::",$filename_only," for pattern::",$search_pattern
			
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
				
				# only debug
				#local-print  -Text ( "Info -- read line {0,3}  : {1}" -f ($counter++),$fline )
				
				## search in the line
				
				foreach ($spat in $search_pattern){
					
					if ($fline	-imatch $spat ) {
					    $log_line=("{0,20}:: Line {1,6} : {2}" -f $filename_only,$counter,$fline )
						$aline+=$log_line		
					}
				}
			}
			until ((-not ($fline)) )		
			
			# write to log file
			if ($aline) {
				
				if ($aline.length -eq 0) {
					$aline+=$filename_only+"::"+"Nothing from interest found"
				}
				
			
				
				set-Content  $log_file $aline
			}
		}
		catch {	
			
			local-print  -ErrorText "Error -- Error ::",$_
		}
		finally {
			if ($sreader) {
				$sreader.close();
			}
		}
		
	
	}
	else {
		local-print  -ErrorText "Error -- File $filename not found"
	
	}	
	<#
		.EXAMPLE
		local-get-file_from_postion -filename "D:\OraPowerShellCodePlex\log\DB_BACKUP_5.log" 10 ("Warning","RMAN-0") "D:\OraPowerShellCodePlex\log\status_mail.log"
		local-get-file_from_postion -filename "D:\OraPowerShellCodePlex\log\DB_BACKUP_5.log" 10 (local-get-oracle-error-pattern) "D:\OraPowerShellCodePlex\log\status_mail.log"
	#>
}
#==============================================================================
#  local-get-oracle-error-pattern
#  return a array of oracle default error search pattern
##

function local-get-oracle-error-pattern{
	
	[String[]] $error_pattern=@()
	
	#General
	$error_pattern+="Error"
	$error_pattern+="idle instance"
	
	#NLS Errors
	$error_pattern+="ORA-12154"
	
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
	
	return $error_pattern
}

#==============================================================================