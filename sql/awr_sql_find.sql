--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   find the sql statement in the sql cache
-- Date:   September 2013
-- Site:   http://orapowershell.codeplex.com
--===============================================================================
define SQL_STATEMENT = &1 


prompt
prompt Parameter 1 = SQL_STATEMENT    => &&SQL_STATEMENT.
prompt


set verify off
SET linesize 130 pagesize 800 recsep OFF

ttitle left  "Search SQL from AWR Repository this text string :  &SQL_STATEMENT." skip 2

column sql_text        format a50 heading "SQL|Text"
column sql_id          format a13 heading "SQL|ID"
column DBID            format 99999999999 heading "DB|Id"
column COMMAND_TYPE    format 99 heading "CMD|Typ"


set long 100

select DBID
	  , SQL_ID
     , SQL_TEXT
     , COMMAND_TYPE
	  /* GPI SQL Analyse */
 from dba_hist_sqltext
where upper(sql_text) like upper('%&&SQL_STATEMENT.%') 
  and sql_text not like '%GPI SQL Analyse%'
order by DBID,SQL_ID
/

prompt ... to get the execution plan call awr_sql.sql with the sql_id

ttitle off
