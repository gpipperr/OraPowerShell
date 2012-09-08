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
    
	$gline = "Info -- Drive {0} free: {1:n} GB from {2:n} GB -- {3:n} % free"
	$bline = "Error -- Drive {0} has only free: {1:n} GB from {2:n} GB -- only {3:n} % free !"

	$freespace = ( get-WmiObject Win32_logicalDisk )

	foreach ($free in $freespace ) {
	
		$per_free=$free.FreeSpace/($free.Size/100)
			
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
		  [String] $filename
		, [int]    $byte_pos 
	)
	
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
			do {
				# read one line
				$fline=$sreader.ReadLine()
				# check if the line is empty (reader not at the end of the file!)
				if ( -not $fline) {
					# the on end of file
					if ( -not ( $sreader.EndOfStream) ){
						$fline=" "
					}
				}				
				local-print  -Text ( "Info -- read line {0,3}  : {1}" -f ($counter++),$fline )
				$aline+=$fline				
			}
			until ((-not ($fline)) )		
			
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
		local-get-file_from_postion -filename "D:\OraPowerShellCodePlex\README.txt" 10
	#>
}


#==============================================================================