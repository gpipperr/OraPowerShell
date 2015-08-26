#==============================================================================
# Author: Gunther Pippèrr ( http://www.pipperr.de )
# Desc:   Start the Oracle Database Service and call sqlplus to start the database in a dedicated status 
# Date:   26.08.2015
# Site:   http://orapowershell.codeplex.com
#==============================================================================
<#
	.NOTES
		Created: 01.2015: Gunther Pippèrr (c) http://www.pipperr.de
		Security:
		(see http://www.pipperr.de/dokuwiki/doku.php?id=windows:powershell_script_aufrufen )
		To switch it off (as administrator)
		get-Executionpolicy -list
		set-ExecutionPolicy -scope CurrentUser RemoteSigned
		or
		sign scripts!
		
	.SYNOPSIS
		Check if the Oracle Service is running, start if nessesary
		Call sqlplus to start for example a database  in the mount status
		
	.DESCRIPTION
		Check if the Oracle Service is running, start if nessesary
		Call sqlplus to start for example a database  in the mount status
		
	.COMPONENT
		Oracle Backup Script
#>

Set-StrictMode -Version 2.0

#==============================================================================
# Set the Environment Variables
# tns Admin
$tns_admin="D:\oracle\TNS_ADMIN" 
$oracle_sid='GPI'
$oracle_home='D:\oracle\products\12.1.0.2\dbhome_1'
$sql_connect_string ="/ as sysdba"

#Set the name of the DB and the Listener Service
$ora_service_name="OracleServiceGPI"
$ora_tns_service_name="OracleOraDB12Home1TNSListener"

#Start the service if stopped
$start_service="true"

#==============================================================================
#set the environment 
try {
	set-item -path env:TNS_ADMIN -value $tns_admin
}
catch {
	new-item -path env: -name TNS_ADMIN -value $tns_admin
}
# Oracle Home
try {
	set-item -path env:ORACLE_HOME -value $oracle_home
}
catch {
	new-item -path env: -name ORACLE_HOME -value $oracle_home
}
# Oracle SID
try {
	set-item -path env:ORACLE_SID -value $oracle_sid
}
catch {
	new-item -path env: -name ORACLE_SID -value $oracle_sid
}

#==============================================================================
#date
$d = get-Date -f  "dd.M.yyy HH:m"

#==============================================================================
#create a logfile the logfile
$stream = [System.IO.StreamWriter] "d:\Last_CallScript.log"

trap {
    Write-Host 'ERROR -- CallScript ' +$error -fore white -back red
    #close the logfile
	$stream.close()
	exit
}
  

$log="LOG -- Start the script at :: " + $d +"`n"
$stream.WriteLine($log)
$log="`n"
$log ="LOG -- tns_admin       ::"+$env:TNS_ADMIN   +"`n"
$log+="LOG -- oracle_sid      ::"+$env:ORACLE_SID +"`n"
$log+="LOG -- oracle_home     ::"+$env:ORACLE_HOME  +"`n"
$log+="LOG -- Listener Srv    ::"+$ora_tns_service_name +"`n"
$log+="LOG -- connect String  ::"+$sql_connect_string   +"`n"
$log+="LOG -- ora_service_name::"+$ora_service_name     +"`n"
$stream.WriteLine($log)
$log="`n"
$stream.Flush()

#==============================================================================
# check the service and start if nessesary

$serviceNames=@()
$serviceNames+=$ora_tns_service_name
$serviceNames+=$ora_service_name

foreach ($service in $serviceNames) {
	$service_running=0
	$stop=0
	$wait=30
	while( $service_running -lt 1)   {		
		#check 
		$ora_service = Get-Service -Name $service -ErrorAction silentlycontinue
	   
		write-host "Service Name"        $service
		write-host "ora_service.Status"  $ora_service.Status
		write-host "service_running::"   $service_running
		write-host "stop::"              $stop
		
		if ($ora_service.Status -eq "Running") {
			$service_running=1;		
		} 
		elseif ($ora_service.Status -eq "Stopped") {
			$service_running=0;		
			# Wait §wait to be sure that the DB service is up
			if ($start_service -eq "true") {
				start-service  -Name $service 
				#-ErrorAction silentlycontinue
			}
			else {
				Start-Sleep -s 1	
			}
		}
		elseif ($ora_service.Status -eq "StartPending") {
			$service_running=0;		
			# Wait §wait to be sure that the DB service is up
			Start-Sleep -s 4	
		}	
		elseif ($ora_service.Status -eq "StopPending") {
			$service_running=2;			
		}
		 
		elseif ($ora_service.Status -eq $null) {
			$service_running=3;
		}
		
		# if this loops runs longer then $wait exit!
		$stop+=1;
		$stream.WriteLine("LOG -- Service::"+$service+" Status:: " + $ora_service.Status + "- Waits:"+$stop)
		$stream.Flush()
		#give up
		if ($stop -gt $wait )  {
			$service_running=4;
		}	
	}
 }
 
#==============================================================================
# Start the database 
# only if the service is running
if ($service_running -eq 1) {

$stream.WriteLine("LOG -- Start sql*plus with ::" + $env:ORACLE_HOME+"\bin\sqlplus -s "+$sql_connect_string)
$log="`n"
$stream.Flush()

# Works not if started over a service as system proces
# must be run under the user!
# must be start a first line of each column
$start_db=@'
startup mount
column inst_id   format 9   heading "Inst|Id"
column status    format A8  heading "Status"
column name      format A8  heading "Instance|Name"
column startzeit format A15 heading "Start|Time"
column host_name format A25 heading "Server|Name"
select inst_id
	  ,status
	  ,instance_name as name
	  ,to_char(STARTUP_TIME, 'dd.mm.YY hh24:mi') as startzeit
	  ,host_name 
  from gv$instance
 order by 1;
quit
'@| & "$env:ORACLE_HOME\bin\sqlplus" -s "$sql_connect_string" 2>&1 | foreach-object { $log+="SQL OUT::",$_.ToString()+"`n" }

$stream.WriteLine($log)
$log="`n"
$stream.Flush()
	
}
elseif ($service_running -eq 2) {
	$log="ERROR -- DB Service $ora_service_name is stopping at the moment - nothing to do"
}
elseif ($service_running -eq 3) {
	$log="ERROR -- DB Service $ora_service_name not exists"
}
elseif ($service_running -eq 4) {
	$log="ERROR -- DB Service $ora_service_name not started after $wait seconds"
}
else {
   $log="ERROR -- DB Service status unknown"	
}

#==============================================================================
#write the result to the log
$stream.WriteLine($log)
$log="`n"
$stream.Flush()

#==============================================================================
#finish
$d = get-Date -f "dd.M.yyy HH:m"
$log="LOG -- End the  script at :: " + $d
$stream.WriteLine($log)
$log="`n"
$stream.Flush()


#==============================================================================
#close the logfile
$stream.close()



