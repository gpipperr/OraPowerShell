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


ttitle left  "DB Trace status" skip 2

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


ttitle off