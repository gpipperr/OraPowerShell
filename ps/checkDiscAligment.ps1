#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   checkDiscAligment
# Date:   14.01.2013
# Site:   http://orapowershell.codeplex.com
#==============================================================================
# Other Examples:
#
#==============================================================================

<#
 	.NOTES
		Created: 01.2013 : Gunther Pippèrr (c) http://www.pipperr.de
		Security:
			(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
			
			to start the script bypass the security:
			%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File d:\PowerShell\certScripts.ps1
			
	.SYNOPSIS
		Check the disks of a system 
		http://www.pipperr.de/dokuwiki/doku.php?id=windows:disk_aligment
	.DESCRIPTION
		Check the disks of a system 
		http://www.pipperr.de/dokuwiki/doku.php?id=windows:disk_aligment
	.COMPONENT
		Info Script
#>

write-host ("-"*80)
write-host "Info -- Check Disk Aligment"
write-host ("-"*80)
# prompt for the Stripe Unit Size

$lun_alloc_size=Read-Host "Please enter the stripe unit size of the storage in byte [4096]:"
if ($lun_alloc_size -lt 1 ) {
	$lun_alloc_size=4096
}

write-host "Info -- Use the stripe unit size of $lun_alloc_size byte"

foreach ( $disk in (Get-WmiObject Win32_DiskPartition | Sort-Object $_.Name ) ) {
	write-host  -ForegroundColor "yellow" ("="*80)
	#"class            :: " +$disk.__CLASS
	"Disk Name         :: " +$disk.Name 
	"Description       :: " +$disk.Description
	"Blocksize         :: " +$disk.BlockSize 
	"Number of Blocks  :: " +$disk.NumberOfBlocks 
	"Size              :: " +$disk.Size
	"Partition_Offset  :: " +$disk.StartingOffset
	#"DeviceID         :: " +$vol.DeviceID
	
	# check the Starting offset to the Stripe Unit Size of the storage
	$aligment_test=($disk.StartingOffset / $lun_alloc_size)
	$fgcolor="green"
	if ( $aligment_test % 1 -gt 0) {
		$fgcolor="red"
	}
	write-host  -ForegroundColor $fgcolor  "Aligment Test Result Partition_Offset / Stripe_Unit_Size :: " + $aligment_test
	
	# get the Win32_LogicalDisk
	foreach ( $vol in ( Get-WmiObject -query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($disk.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition" ) ){
		write-host ("-"*20)
		"--          Check the Aligment over the file system File Allocation Unit Size" 
		#"--      Class      :: "+$vol.__CLASS
		#"--      DeviceID   :: "+$vol.DeviceID
		#"--      Driveletter:: "+$vol.DriveLetter 
		#"--      Label      :: "+$vol.Label
		#"--      Blocksize  :: "+$vol.Blocksize
		foreach ( $vol2 in (Get-WmiObject Win32_Volume  | where-object {$_.DriveLetter -eq $vol.DeviceID } )) {
			#"--         Class		                :: "+$vol2.__CLASS
			"--          DeviceID                   :: "+$vol2.DeviceID
			"--          Driveletter                :: "+$vol2.DriveLetter 
			"--          Label                      :: "+$vol2.Label
			"--          File_Allocation_Unit_Size  :: "+$vol2.Blocksize
			$aligment_test=($disk.StartingOffset / $vol2.Blocksize)
			$fgcolor="green"
			if ( $aligment_test % 1 -gt 0) {
				$fgcolor="red"
			}
			write-host  -ForegroundColor $fgcolor  "--          Aligment Partition_Offset / File_Allocation_Unit_Size:: " + $aligment_test
			$aligment_test=($lun_alloc_size / $vol2.Blocksize)
			$fgcolor="green"
			if ( $aligment_test % 1 -gt 0) {
				$fgcolor="red"
			}
			write-host  -ForegroundColor $fgcolor  "--          Aligment Stripe_Unit_Size / File_Allocation_Unit_Size:: " + $aligment_test
		}
	}
}




