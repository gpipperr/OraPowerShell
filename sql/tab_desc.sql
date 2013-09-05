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

define OWNER    = '&1' 
define TAB_NAME = '&2' 

prompt
prompt Parameter 1 = Owner Name  => &&OWNER.
prompt Parameter 2 = Tab Name    => &&TAB_NAME.
prompt

column column_name    format a20   heading "Column name" 
column data_type      format a25   heading "Data type" 
column data_default   format a20   heading "Column default"
column nullable       format a3    heading "Null ?"
column char_length    format a4   heading "Char Count"

ttitle left  "Describe the columns of a table" skip 2

select
	  column_name
	, case data_type 
	   when 'VARCHAR2' then 'varchar2('||lpad(data_length,5)||' '|| decode(char_used,'B','Byte','C','Char',char_used)||')'
	   when 'NUMBER'   then 'number  ('||lpad(data_length,5)|| nvl(data_precision,'') ||' '||  nvl(DATA_SCALE,'') ||')'
       when 'DATE'     then  'date'
       else rpad(lower(data_type),8) ||'('||lpad(data_length,5)||nvl(data_precision,'') ||')'
      end as data_type
	, case when char_length > 0 then to_char(char_length)  else '-' end as char_length
	, decode(nullable,'Y','YES','NO') as nullable
	, data_default	
 from all_tab_columns 
 where table_name like upper('&&TAB_NAME.')
   and owner      like upper('&&OWNER.')
order by COLUMN_ID
/

ttitle off
