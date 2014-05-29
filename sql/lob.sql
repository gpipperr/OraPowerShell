set verify  off
set linesize 120 pagesize 4000 recsep OFF

define OWNER    = '&1' 

prompt
prompt Parameter 1 = Owner Name  => &&OWNER.
prompt


column owner        format a12 heading "User"
column table_name   format a30 heading "Table name"
column column_name  format a20 heading "Column|Name"
column segment_name format a30 heading "Segment|Name"
column IN_ROW       format a3 heading "In|Row"
column SECUREFILE   format a3 heading "Sec|File"

select owner
     , table_name
	 , column_name
	 , segment_name  
	 , IN_ROW
	 , SECUREFILE
from dba_lobs 
where upper(owner)=upper('&&OWNER.')
/