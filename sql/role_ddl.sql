--==============================================================================
-- GPI - Gunther Pippèrr
-- Desc:   get DDL of a role
--==============================================================================
set verify  off
set linesize 130 pagesize 4000 recsep off

define ROLENAME    = '&1'

prompt
prompt Parameter 1 = Role Name => &&ROLENAME.
prompt

variable ddllob clob

set heading off
set echo off

set long 1000000;

spool create_role_script_&&ROLENAME..sql

declare
   cursor c_role
   is
      select role
        from dba_roles
       where upper (role) like upper ('&&ROLENAME.');

   v_role   varchar2 (32);
begin
   for o_rec in c_role
   loop
      v_role := o_rec.role;

      :ddllob := dbms_metadata.get_ddl ('ROLE', v_role);

      :ddllob := :ddllob || chr (10) || chr (10) || '-- Role Grants : ' || chr (10);

      begin
         :ddllob := :ddllob || dbms_metadata.get_granted_ddl ('ROLE_GRANT', v_role);
      exception
         when others
         then
            :ddllob := :ddllob || chr (10) || chr (10) || '-- NO DDL for Role Grants found' || chr (10);
      end;

      :ddllob := :ddllob || chr (10) || chr (10) || '-- System Grants : ' || chr (10);

      begin
         :ddllob := :ddllob || dbms_metadata.get_granted_ddl ('SYSTEM_GRANT', v_role);
      exception
         when others
         then
            :ddllob := :ddllob || chr (10) || chr (10) || '-- NO DDL for Sytem Grants found' || chr (10);
      end;

      :ddllob := :ddllob || chr (10) || chr (10) || '-- Object Grants : ' || chr (10);

      begin
         :ddllob := :ddllob || dbms_metadata.get_granted_ddl ('OBJECT_GRANT', v_role);
      exception
         when others
         then
            :ddllob := :ddllob || chr (10) || chr (10) || '-- NO DDL for Object Grants found' || chr (10);
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
prompt ... to create the user call create_role_script_&&ROLENAME..sql in the target DB
prompt ...