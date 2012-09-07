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
	
		$used_space=$free.Size-$free.FreeSpace
		$per_free=$free.FreeSpace/($free.Size/100)
	

		if ( $per_free -lt 10) {
			local-print  -ErrorText	($bline -f $free.DeviceID,($free.FreeSpace/1GB),($free.Size/1GB),$per_free)
		}
		else {
			local-print  -Text		($gline -f $free.DeviceID,($free.FreeSpace/1GB),($free.Size/1GB),$per_free)
		}		
	}
}


#==============================================================================