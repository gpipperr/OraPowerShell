--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   :   HTML Report for SQL queries with the most resource usage
-- see :   http://www.pipperr.de/dokuwiki/doku.php?id=dba:index_column_usage
-- Date:   September 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

col SPOOL_NAME_COL new_val SPOOL_NAME
 
SELECT replace(ora_database_name||'_'||SYS_CONTEXT('USERENV','HOST')||'_'||to_char(sysdate,'dd_mm_yyyy_hh24_mi')||'_top_sql.html','\','_') 
--' resolve syntax highlight bug FROM my editer .-(
  AS SPOOL_NAME_COL
FROM dual
/

set verify off
SET linesize 130 pagesize 200 recsep OFF

column sql_text format a35 heading "SQL|Text"
column sql_id   format a13 heading "SQL|ID"
column parsing_user_name  format a10 heading "Parsing|Schema"
column executions  format 999G999G999 heading "Exec"
column buffer_gets format 999G999G999 heading "Buffer|Gets"
column disk_reads  format 999G999G999 heading "Disks|Reads"
column cpu_time    format 999G999G999 heading "CpuTime|microseconds"
column sorts       format 999G999G999 heading "Sorts"
column avg_bufferget_per_ex  format 999G999D99 heading "AVG Buffer gets|Executions"
column avg_disk_reads_per_ex format 999G999D99 heading "AVG Disk reads|Executions"
column avg_sort_per_ex       format 999G999D99 heading "AVG Sorts|Executions"
column avg_cpu_per_ex        format 99G999G999D99 heading "AVG CPU|Executions"

spool &&SPOOL_NAME


set markup html on

ttitle center "Top 20 SQL Statements with high buffer gets > 10000" SKIP 2

select * from
(
	select  SQL_ID
		  , (select username from dba_users where user_id=parsing_user_id) as "Parsing User"
		  , executions
		  , loads
		  , buffer_gets
		  , disk_reads
		  , trunc(buffer_gets/(executions),2) avg_bufferget_per_ex
		  , trunc(disk_reads/(executions),2)  avg_disk_reads_per_ex
		  , sql_text 
	 from v$sqlarea
	where executions > 1
	  and buffer_gets > 10000
	order by buffer_gets desc
)
where rownum <=20;

ttitle center "Top 20 SQL Statements with high sorts" SKIP 2

select * from
(
	select  SQL_ID
		  , (select username from dba_users where user_id=parsing_user_id) as "Parsing User"
		  , executions
		  , loads
		  , sorts
		  , buffer_gets
		  , disk_reads
		  , trunc(sorts/(executions),2) avg_sort_per_ex		  
		  , sql_text 
	 from v$sqlarea
	where executions > 1
	  and sorts > 10
	order by sorts desc
)
where rownum <=20;


ttitle center "Top 20 SQL Statements with high CPU" SKIP 2

select * from
(
	select  SQL_ID
		  , (select username from dba_users where user_id=parsing_user_id) as "Parsing User"
		  , executions
		  , loads
		  , cpu_time
		  , buffer_gets
		  , disk_reads
		  , trunc(cpu_time/(executions),2) avg_cpu_per_ex
		  , sql_text 
	 from v$sqlarea
	where executions > 1
	  and cpu_time > 10
	order by cpu_time desc
)
where rownum <=20;

set markup html off

spool off
ttitle off

-- works only in a ms windows environment
-- auto start of the result in a browser window
host &&SPOOL_NAME