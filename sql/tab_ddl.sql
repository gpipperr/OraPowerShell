--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   extract the DDL of a object in the database
--
-- Parameter 2: Owner of the table/object
-- Parameter 1: Name of the table/object
--
-- Must be run with dba privileges
-- 
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify  off
set linesize 130 pagesize 4000 recsep OFF

define OWNER    = '&1' 
define TAB_NAME = '&2' 

prompt
prompt Parameter 1 = Owner Name => &&OWNER.
prompt Parameter 2 = Tab Name   => &&TAB_NAME.
prompt


variable ddllob clob

set heading off
set echo off

set long 64000;

declare
 cursor c_tab_idx is
  select index_name,owner from dba_indexes where table_name='&&TAB_NAME.' and TABLE_OWNER='&&OWNER.';
 
 v_type varchar2(32);
begin

	select OBJECT_TYPE into v_type from dba_objects where object_name ='&&TAB_NAME.' and owner='&&OWNER.';
	
	:ddllob:=dbms_metadata.get_ddl(v_type ,'&&TAB_NAME.','&&OWNER.'); 
  
	-- get the index DDL for this table
	if v_type = 'TABLE' then
		for rec in c_tab_idx
		loop
			
			:ddllob:=:ddllob||chr(10)||chr(10)||'-- DDL for Index : '||rec.index_name||chr(10);
			
			:ddllob:=:ddllob||dbms_metadata.get_ddl('INDEX',rec.index_name,rec.owner);
			
	    end loop;
	end if;

end;
/

print ddllob


undefine ddllob


set heading on