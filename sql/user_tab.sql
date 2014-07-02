--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the tables and views  of this user
-- Parameter 1: Name of the User
--
-- Date:   September 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify off

define USERNAME = &1 

prompt
prompt Parameter 1 = User Name   => &&USERNAME.
prompt


SET linesize 120 pagesize 400 recsep OFF

ttitle left  "Tables and Views for this user &&USERNAME." skip 2

column owner      format a15 heading "Qwner" 
column table_name format a30 heading "Table/View Name"
column otype      format a5 heading "Type"
column comments   format a40 heading "Comment on this table/view"
COLUMN tablespace_name format a20 heading "Tablespace Name"

select  t.owner
      , t.table_name
	  , 'table' as otype
	  , nvl(c.comments,'n/a')  as comments
	  , t.tablespace_name
from dba_tables t
    ,dba_tab_comments c
 where upper(t.owner) like upper('%&&USERNAME.%')
 and c.table_name (+) = t.table_name
 and c.owner (+) = t.owner
 and c.table_type (+)= 'TABLE'
union
 select  v.owner
       , v.view_name
	   , 'view'  as otype
	   , nvl(c.comments,'n/a')  as comments
		,'n/a'
  from dba_views v
      ,dba_tab_comments c
 where upper(v.owner) like upper('%&&USERNAME.%')
 and c.table_name (+) = v.view_name
 and c.owner (+) = v.owner
 and c.table_type (+)= 'VIEW'
order by 1,2
/

ttitle off
