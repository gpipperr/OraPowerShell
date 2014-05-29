--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Get DDL of the USEr
-- Date:   Mai 2014
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify  off
set linesize 130 pagesize 4000 recsep OFF

define USERNAME    = '&1' 

prompt
prompt Parameter 1 = USER Name => &&USERNAME.
prompt

variable ddllob clob

set heading off
set echo off

set long 1000000;

spool create_user_script_&&USERNAME..sql

declare
 cursor c_user is
  select username
    from dba_users 
	where upper(username) like upper('&&USERNAME.');
 
 v_user varchar2(32);
begin
   for o_rec in c_user
	loop
		v_user:=o_rec.username;
		
		:ddllob:=dbms_metadata.get_ddl('USER', v_user);  	
		
		:ddllob:=:ddllob||chr(10)||chr(10)||'-- Role Grants : '||chr(10);
		begin
			:ddllob:=:ddllob||dbms_metadata.get_granted_ddl('ROLE_GRANT',v_user);					
	   exception 
			when others then
			:ddllob:=:ddllob||chr(10)||chr(10)||'-- NO DDL for Role Grants found'||chr(10);
		end;		
		
		:ddllob:=:ddllob||chr(10)||chr(10)||'-- System Grants : '||chr(10);
		begin
			:ddllob:=:ddllob||dbms_metadata.get_granted_ddl('SYSTEM_GRANT',v_user);					
	   exception 
			when others then
			:ddllob:=:ddllob||chr(10)||chr(10)||'-- NO DDL for Sytem Grants found'||chr(10);
		end;		
		
		:ddllob:=:ddllob||chr(10)||chr(10)||'-- Object Grants : '||chr(10);
		begin
			:ddllob:=:ddllob||dbms_metadata.get_granted_ddl('OBJECT_GRANT',v_user);					
	   exception 
			when others then
			:ddllob:=:ddllob||chr(10)||chr(10)||'-- NO DDL for Object Grants found'||chr(10);
		end;						
	end loop;
end;
/

print ddllob

undefine ddllob

spool off;

set head on
set pages 1000

prompt ...
prompt ... to create the user call create_user_script_&&USERNAME..sql in the target DB
prompt ...
