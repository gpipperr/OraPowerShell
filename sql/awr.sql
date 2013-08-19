--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script ASM Disk Overview
-- Date:   08.2013
-- Site:   http://orapowershell.codeplex.com

-- Analyse the SYSAUX Tablespace

--==============================================================================

SET pagesize 300
SET linesize 250

---
@space_tablespace.sql SYSAUX
--


ttitle left  "AWR Snapshots count" skip 2
column snapshot_count format 999999 heading "Snapshot Count"

select count(*) as snapshot_count from sys.wrm$_snapshot
/

ttitle left  "AWR Snapshots time frame" skip 2
column snap_id format 999999 heading "Snap|Id"
column start_time format a21 heading "Start|time"
column end_time   format a21 heading "End|time"


select  snap_id
      , to_char(begin_interval_time,'dd.mm.yyyy hh24:mi:ss') as start_time
	  , to_char(end_interval_time ,'dd.mm.yyyy hh24:mi:ss')  as end_time
 from sys.wrm$_snapshot 
where   ( 
        snap_id = ( select min (snap_id) from sys.wrm$_snapshot) 
    or  snap_id = ( select max(snap_id) from sys.wrm$_snapshot) 
    )
order by snap_id asc
/


ttitle left  "AWR Usage Overview" skip 2

column occupant_name  format a25
column schema_name    format a18
column move_procedure format a40
column space_usage    format 9G999 heading "Space | Usage (M)"

select   occupant_name
       , round( space_usage_kbytes/1024) as space_usage  
       , schema_name
       , move_procedure
 from  v$sysaux_occupants  
 where space_usage_kbytes > 1
order by 2 desc    
/


DOC 
-------------------------------------------------------------------------------
 to drop some snapshots from the repostitory you can use this command:
 begin                                                               
  dbms_workload_repository.drop_snapshot_range( low_snap_id  => <min_snap_id>
                                              , high_snap_id => <max_snap_id>);                                         
 end;
 / 
-------------------------------------------------------------------------------
#

ttitle off
