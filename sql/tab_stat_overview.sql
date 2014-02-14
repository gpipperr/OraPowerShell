--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Get the statistic settings of all tables of a user
-- Parameter 1: Name of the table
--
-- Must be run with dba privileges
-- 
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

define USER_NAME  = &1

prompt
prompt Parameter 1 = Owner Name => &&USER_NAME.
prompt

SET linesize 150 pagesize 2000 recsep OFF

ttitle "Read Statistic Values for all tables of this user &USER_NAME." SKIP 2

column table_name  format a32

select  table_name
      , status
	  , to_char(LAST_ANALYZED,'dd.mm.yyyy hh24:mi') as LAST_ANALYZED
	  , NUM_ROWS
	  , AVG_SPACE
	  , CHAIN_CNT
	  , AVG_ROW_LEN
 from dba_tables
where owner   like '&USER_NAME.'
order by nvl(NUM_ROWS,1) asc
/

prompt ... to anaylse the space Usage use tab.sql
prompt ... to refresh statistic use  EXEC DBMS_STATS.GATHER_TABLE_STATS ('&USER_NAME.', 'TABLE_NAME');

ttitle off
