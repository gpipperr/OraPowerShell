--==============================================================================
-- GPI - Gunther Pippèrr
-- get my user connection
--==============================================================================
set linesize 130 pagesize 300 recsep off

column MY_USER_AND_SERVICE format a100 heading "My Connection is"

select  'Instance :: '||SYS_CONTEXT('USERENV', 'INSTANCE_NAME')||' ++ Service :: '||SYS_CONTEXT('USERENV', 'SERVICE_NAME') || ' ++ User :: '||user ||' ++ SID :: '||sys_context('userenv','SID')||' + Inst ID :: '||sys_context('userenv','INSTANCE') as MY_USER_AND_SERVICE
  from dual
/

prompt
