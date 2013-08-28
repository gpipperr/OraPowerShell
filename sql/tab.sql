--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   search the table in the database
-- Parameter 1: Name of the table
--
-- Must be run with dba privileges
-- 
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify  off
set linesize 120 pagesize 4000 recsep OFF

define TAB_NAME = '&1' 

prompt
prompt Parameter 1 = Tab Name          => &&TAB_NAME.
prompt

column owner      format a15 heading "Qwner" 
column table_name format a30 heading "Table/View Name"
column otype      format a5 heading "Type"
column comments   format a60 heading "Comment on this table/view"

select  t.owner
      , t.table_name
	  , 'table' as otype
	  , nvl(c.comments,'n/a')  as comments
from dba_tables t
    ,dba_tab_comments c
 where upper(t.table_name) like upper('%&&tab_name.%')
 and c.table_name (+) = t.table_name
 and c.owner (+) = t.owner
 and c.table_type (+)= 'TABLE'
union
 select  v.owner
       , v.view_name
	   , 'view'  as otype
	   , nvl(c.comments,'n/a')  as comments
  from dba_views v
      ,dba_tab_comments c
 where upper(v.view_name) like upper('%&&tab_name.%')
 and c.table_name (+) = v.view_name
 and c.owner (+) = v.owner
 and c.table_type (+)= 'VIEW'
order by 1,2
/

