--==============================================================================
-- Author: Gunther Pipp�rr ( http://www.pipperr.de )
-- Desc:   get Information about my session
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify off

SET linesize 150 pagesize 180

ttitle left  "My Oracle session and his process" skip 2

column process_id format a8     heading "Process|ID"
column inst_id    format 99     heading "Inst|ID"
column username   format a8     heading "DB User|name"
column osusername   format a8   heading "OS User|DB Process"
column sid        format 99999  heading "SID"
column serial#    format 99999  heading "Serial"
column machine    format a14    heading "Remote|pc/server"
column terminal   format a14    heading "Remote|terminal"
column program    format a17    heading "Remote|program"
column module     format a15    heading "Remote|module"
column client_info format a15   heading "Client|info"
column pname       format a8    heading "Process|name"
column tracefile   format a20   heading "Trace|File"

select p.inst_id  
   , vs.sid
	, vs.serial#
   , nvl(vs.username,'n/a') as username
	, p.username as osusername
	, p.pname		
	, to_char(p.spid) as process_id
	, vs.machine
	--, p.terminal
	, vs.module
    , vs.program
	, vs.client_info 	
	--, substr(p.tracefile,length(p.tracefile)-REGEXP_INSTR(reverse(p.tracefile),'[\/|\]')+2,1000) as tracefile
	--, p.tracefile
from gv$session vs
   , gv$process p
where vs.paddr=p.addr
  and vs.inst_id=p.inst_id
   and vs.sid=sys_context('userenv','SID')
	and vs.inst_id=sys_context('userenv','INSTANCE')  
order by vs.username
       , p.inst_id
		 ,p.spid
/  

ttitle left  "Trace File Locations" skip 2

column full_trace_file_loc  format a100  heading "Trace|File"

SELECT value as full_trace_file_loc 
  FROM v$diag_info 
 WHERE  name = 'Default Trace File'
/ 

--select p.inst_id  
--    , to_char(p.spid) as process_id
--    , p.tracefile as full_trace_file_loc
--from gv$session vs
--   , gv$process p
--where vs.paddr=p.addr
--  and vs.inst_id=p.inst_id
--   and vs.sid=sys_context('userenv','SID')
--	and vs.inst_id=sys_context('userenv','INSTANCE')
--order by vs.username
--       , p.inst_id
--/  

ttitle left  "TAF Setting" skip 2
column inst_id    format 99       heading "Inst|ID"
column username   format a14      heading "DB User|name"
column machine    format a36      heading "Remote|pc/server"
column failover_type   format a6  heading "Fail|type"
column failover_method format a6 heading "Fail|method"
column failed_over     format a6 heading "Fail|over"

select inst_id
     , machine
	  , username
     , failover_type
	  , failover_method
	  , failed_over	  
 from gv$session
where   sid=sys_context('userenv','SID')
	and inst_id=sys_context('userenv','INSTANCE')  
/

ttitle off



