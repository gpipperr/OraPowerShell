--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   search a column in the database
-- Parameter 1: Name of the column
--
-- Must be run with dba privileges
-- 
-- Site:   http://orapowershell.codeplex.com
--==============================================================================


set verify  off
set linesize 140 pagesize 4000 recsep OFF

define COL_NAME = '&1' 

prompt
prompt Parameter 1 = Column Name          => &&COL_NAME.
prompt

column owner       format a10 heading "Qwner" 
column table_name  format a20 heading "Table|Name"
column COLUMN_NAME format a15 heading "Column|Name"
column comments    format a30 heading "Comment on this table/view"
column data_type      format a15 heading "Data type" 
column data_default   format a10 heading "Column default"
column nullable       format a3  heading "Null ?"
column char_length    format a4  heading "Char Count"


select  t.OWNER
		, t.TABLE_NAME
		, t.COLUMN_NAME
		, case t.data_type 
	      when 'VARCHAR2' then 'varchar2('||lpad(data_length,5)||' '|| decode(t.char_used,'B','Byte','C','Char',t.char_used)||')'
	      when 'NUMBER'   then 'number  ('||lpad(data_length,5)|| nvl(t.data_precision,'') ||' '||  nvl(t.DATA_SCALE,'') ||')'
         when 'DATE'     then  'date'
		   when 'LONG' then 'long'
         else rpad(lower(t.data_type),8) ||'('||lpad(t.data_length,5)||nvl(t.data_precision,'') ||')'
       end as data_type
		, case when char_length > 0 then to_char(t.char_length)  else '-' end as char_length
		, decode(nullable,'Y','YES','NO') as nullable
		, data_default	
		, c.comments
 from dba_tab_columns t,DBA_COL_COMMENTS c
where t.COLUMN_NAME like upper('&&COL_NAME.')
 and t.OWNER=c.OWNER (+)
 and t.TABLE_NAME = c.TABLE_NAME (+)
 and t.COLUMN_NAME = c.COLUMN_NAME (+)
order by OWNER,TABLE_NAME,COLUMN_NAME
/
