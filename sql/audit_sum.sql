--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Query the audit log entries
--
-- Must be run with dba privileges
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 120 pagesize 400 recsep OFF

ttitle left  "Audit Log entries " skip 2

column username    format a10  heading "DB User|name"
column action_name format a25  heading "Action|name"
column first_log   format a25  heading "First|entry"
column last_log    format a25  heading "Last|entry"
column entries     format 999G999G999 heading "Audit|entries"

ttitle left  "Audit log from time until time" skip 2

select to_char(min(timestamp),'dd.mm.yyyy hh24:mi:ss') as first_log
	 , to_char(max(timestamp),'dd.mm.yyyy hh24:mi:ss') as last_log
	 , count(*) as entries
 from dba_audit_object
order by 1
/

ttitle left  "Audit log entries " skip 2

select username
     , action_name
	 , count(*) as entries
	 , to_char(min(timestamp),'dd.mm.yyyy hh24:mi:ss') as first_log
	 , to_char(max(timestamp),'dd.mm.yyyy hh24:mi:ss') as last_log
 from dba_audit_object
group by username,action_name
order by 1
/


prompt
prompt ... for detail information call:                  audit_rep.sql
prompt ... for the space usage of the audit$ table call: tab_space.sql
prompt


ttitle off
