--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   show the trace status of the DB
--==============================================================================

set verify off

SET linesize 120 pagesize 500 recsep OFF


column trace_type      format a15
column primary_id      format a15
column qualifier_id1   format a15
column qualifier_id2   format a15
column waits           format a5
column binds           format a5
column plan_stats      format a15
column instance_name   format a20


ttitle left  "DB Trace status for Using DBMS_MONITOR only" skip 2

select trace_type
	  , primary_id
	  , qualifier_id1
	  , qualifier_id2
	  , waits
	  , binds
	  , plan_stats
	  , instance_name
 from dba_enabled_traces
order by
instance_name
/


ttitle left  "DB Trace status for all user sessions" skip 2

column inst_id          format 99            heading "Inst|ID"
column username         format a20           heading "DB User|name"
column sid              format 99999         heading "SID"
column serial#          format 99999         heading "Serial"
column program    format a16    heading "Remote|program"
column module     format a16    heading "Remote|module"
column client_info format a10   heading "Client|info"
column client_identifier format A10 heading "Client|identifier"
column action format a30

select  inst_id 
      , sid
	   , serial#
	   , username	
		--, module
		, ACTION
		, to_char(LOGON_TIME,'dd.mm hh24:mi') as LOGON_TIME
      , client_identifier
	   , client_info	
 from gv$session 
where SQL_TRACE != 'DISABLED'
order by inst_id
/

ttitle off