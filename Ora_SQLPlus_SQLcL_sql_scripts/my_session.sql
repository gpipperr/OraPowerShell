--==============================================================================
-- GPI - Gunther Pippèrr
-- Desc:   get Information about my session
--
--==============================================================================
set verify off
set linesize 130 pagesize 300 

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
       ,  vs.sid
       ,  vs.serial#
       ,  nvl (vs.username, 'n/a') as username
       ,  p.username as osusername
       ,  p.pname
       ,  to_char (p.spid) as process_id
       ,  vs.machine
       --, p.terminal
       ,  vs.module
       ,  vs.program
       ,  vs.client_info
    --, substr(p.tracefile,length(p.tracefile)-REGEXP_INSTR(reverse(p.tracefile),'[\/|\]')+2,1000) as tracefile
    --, p.tracefile
    from gv$session vs, gv$process p
   where     vs.paddr = p.addr
         and vs.inst_id = p.inst_id
         and vs.sid = sys_context ('userenv', 'SID')
         and vs.inst_id = sys_context ('userenv', 'INSTANCE')
order by vs.username, p.inst_id, p.spid
/

ttitle left  "My SID and my Serial over dbms_debug_jdwp" skip 2

SELECT dbms_debug_jdwp.current_session_id sid
     , dbms_debug_jdwp.current_session_serial serial
FROM dual
/

ttitle left  "Trace File Locations" skip 2

column full_trace_file_loc  format a100  heading "Trace|File"

select value as full_trace_file_loc
  from v$diag_info
 where name = 'Default Trace File'
/

--select p.inst_id
--    , to_char(p.spid) as process_id
--    , p.tracefile as full_trace_file_loc
--from gv$session vs
--   , gv$process p
--where vs.paddr=p.addr
--  and vs.inst_id=p.inst_id
--   and vs.sid=sys_context('userenv','SID')
--    and vs.inst_id=sys_context('userenv','INSTANCE')
--order by vs.username
--       , p.inst_id
--/

ttitle left  "Check if this Session is connected via TCP with SSL TCPS or TCP" skip 2


SELECT SYS_CONTEXT('USERENV','NETWORK_PROTOCOL') AS connect_protocol 
  FROM dual
/  


ttitle left  "TAF Setting" skip 2
column inst_id    format 99       heading "Inst|ID"
column username   format a14      heading "DB User|name"
column machine    format a36      heading "Remote|pc/server"
column failover_type   format a6  heading "Fail|type"
column failover_method format a6 heading "Fail|method"
column failed_over     format a6 heading "Fail|over"

select inst_id
     ,  machine
     ,  username
     ,  failover_type
     ,  failover_method
     ,  failed_over
  from gv$session
 where     sid = sys_context ('userenv', 'SID')
       and inst_id = sys_context ('userenv', 'INSTANCE')
/
ttitle left  "Session NLS Lang Values" skip 2

select sys_context ('USERENV', 'LANGUAGE') as NLS_LANG_Parameter from dual;

ttitle left  "Session NLS Values" skip 2

column parameter format a24 heading "NLS Session Parameter"
column value     format a30 heading "Setting"

select PARAMETER, value
    from nls_session_parameters
order by 1
/




ttitle off