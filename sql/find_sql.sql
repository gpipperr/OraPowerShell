--==============================================================================
-- Author: Gunther Pipp�rr ( http://www.pipperr.de )
-- Desc:   find the sql statement in the sql cache
-- Date:   September 2013
-- Site:   http://orapowershell.codeplex.com
--===============================================================================

define SQL_STATEMENT = &1 

set verify off
SET linesize 130 pagesize 400 recsep OFF


ttitle left  "SQL Plan from Cursor Cache ID:  &SQL_ID." skip 2

column sql_text format a35 heading "SQL|Text"
column sql_id   format a13 heading "SQL|ID"
column parsing_user_name  format a10 heading "Parsing|Schema"
column executions  format 999G999 heading "Exec"
column buffer_gets format 999G999 heading "Buffer|Gets"
column disk_reads  format 999G999 heading "Disks|Reads"
column cpu_time    format 999G999 heading "Cpu|Time"
column sorts       format 999G999 heading "Sorts"

select  SQL_ID
	  , (select username from dba_users where user_id=parsing_user_id) as parsing_user_name
	  , sorts
	  , executions
	  , buffer_gets
	  , disk_reads
	  , cpu_time
	  , sql_text
 from v$sqlarea
where upper(sql_text) like upper('%&&SQL_STATEMENT.%')
/

prompt ... to get the execution plan call awr_sql.sql with the sql_id

ttitle off
