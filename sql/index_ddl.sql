--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   extract the DDL of index  in the database
--
-- Parameter 2: Owner of the table/object
-- Parameter 1: Name of the index
--
-- Must be run with dba privileges
-- 
--==============================================================================

set verify  off
set linesize 130 pagesize 4000 recsep OFF

define OWNER    = '&1' 
define INDEX_NAME = '&2' 

prompt
prompt Parameter 1 = Owner Name   => &&OWNER.
prompt Parameter 2 = Index Name   => &&INDEX_NAME.
prompt

variable ddllob clob

set heading off
set echo off

set long 1000000;

declare
 cursor c_tab_idx is
  select index_name
       , owner 
     from dba_indexes 
	 where index_name=upper('&&INDEX_NAME.') 
	   and TABLE_OWNER=upper('&&OWNER.');
begin
   -- 
	:ddllob:='-- call Index DLL for Index &&OWNER..&&INDEX_NAME.';
   dbms_output.put_line(:ddllob);
	
	-- get the index DDL for this table
	for rec in c_tab_idx
	loop
		:ddllob:=:ddllob||chr(10)||chr(10)||'-- DDL for Index : '||rec.index_name||chr(10);
		:ddllob:=:ddllob||dbms_metadata.get_ddl('INDEX',rec.index_name,rec.owner);				
	end loop;	
end;
/

print ddllob

undefine ddllob

set heading on
