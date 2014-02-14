--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   check the status of oracle streams
-- Date:   02.2014
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
-- http://docs.oracle.com/cd/E11882_01/server.112/e10705/toc.htm
-- http://www.oracle11ggotchas.com/articles/Resolving%20archived%20log%20file%20gaps%20in%20Streams.pdf


SET linesize 130 pagesize 300 recsep OFF


column running_inst           format 99 heading "In|St"
column capture_process_status format a10 heading "CaptureP|Status"
column apply_process_status   format a10 heading "ApplyP|Status"
column apply_state            format a10 heading "Apply|state"
column capture_state          format a30 heading "Capture|State"
column hwm_message_create_time format a18 heading "MessageC|Time"
column delay_min               format 9999999 heading "Delay|Minute"
column total_applied           format 9999999 heading "Total|Applied"

select to_char(sysdate,'dd.mm.yyyy hh24:mi') as act_date from dual;

select capture_state.inst_id as running_inst
     , capture_status.status as capture_process_status
     , apply_status.status   as apply_process_status
     , capture_state.state   as capture_state
     , apply_state.state     as apply_state
     , to_char(apply_state.hwm_message_create_time,'dd.mm.yyyy hh24:mi') as hwm_message_create_time
     , round((sysdate-apply_state.hwm_message_create_time)*24*60) as delay_min
     , apply_state.total_applied
from (SELECT 1 as jc, state, inst_id FROM gv$streams_capture) capture_state
	, (select 1 as jc, state, hwm_message_create_time, total_applied from gv$streams_apply_coordinator ) apply_state
	, (select 1 as jc, status from dba_apply) apply_status
	, (select 1 as jc, status from dba_capture) capture_status 
where  capture_status.jc=apply_state.jc(+)
 and capture_status.jc=apply_status.jc(+)
 and capture_status.jc=capture_state.jc(+)
/



select thread
      , consumer_name
      , seq+1 first_seq_missing 
		, seq+(next_seq-seq-1) last_seq_missing
		, next_seq-seq-1 missing_count 
 from (select THREAD# thread
            , SEQUENCE# seq
				, lead (SEQUENCE#, 1, SEQUENCE#) over (partition by thread# order by sequence#) next_seq  
				, consumer_name
		  from dba_registered_archived_log
       where RESETLOGS_CHANGE#=(select max(RESETLOGS_CHANGE#) from dba_registered_archived_log)		
		) 
where next_seq - seq > 1 
order by 1,2
/ 

 

-- column component_name 			heading 'component|name' 	format a24
-- column component_type 			heading 'component|type' 	format a12
-- column action 						heading 'action' 				format a18
-- column source_database_name 	heading 'source|database' 	format a10
-- column object_owner 				heading 'object|owner' 		format a8
-- column object_name 				heading 'object|name' 		format a18
-- column command_type 				heading 'command|type' 		format a7
--  
-- select component_name
--        ,component_type
--        ,action
--        ,source_database_name
--        ,object_owner
--        ,object_name
--        ,command_type
-- 		 ,ACTION_DETAILS
-- 		 ,to_char(MESSAGE_CREATION_TIME,'dd.mm.yyyy hh24:mi' )
--    from v$streams_message_tracking
-- /

COLUMN CONSUMER_NAME HEADING 'Capture|Process|Name' FORMAT A18
COLUMN SOURCE_DATABASE HEADING 'Source|Database' FORMAT A10
COLUMN SEQUENCE# HEADING 'Sequence|Number' FORMAT 99999999
COLUMN NAME HEADING 'Required|Archived Redo Log|File Name' FORMAT A60
 
select  r.consumer_name
      , r.source_database
      , r.sequence# 
      , r.name 
		, to_char(FIRST_TIME,'dd.mm hh24:mi') as start_time
from dba_registered_archived_log r
   , dba_capture c
where r.consumer_name =  c.capture_name 
  and r.next_scn     >=  c.required_checkpoint_scn
 order by FIRST_TIME,THREAD#  asc		  
/		  
		  
-- select THREAD#
--      ,SEQUENCE#
-- 	  , NAME
-- 	  , to_char(FIRST_TIME,'dd.mm hh24:mi') as first_time
-- 	  ,NEXT_TIME
-- 	  ,FIRST_SCN 
-- from DBA_REGISTERED_ARCHIVED_LOG 
-- where &SCN between FIRST_SCN and next_scn 
-- order by THREAD#,SEQUENCE#
-- /		  

