--- get my user connection
column MY_USER_AND_SERVICE format a83 heading "My Connection is"

select  'Instance :: '||SYS_CONTEXT('USERENV', 'INSTANCE_NAME')||' ++ Service :: '||SYS_CONTEXT('USERENV', 'SERVICE_NAME') || ' ++ User :: '||user ||' ++ SID :: '||sys_context('userenv','SID')||' + Inst ID :: '||sys_context('userenv','INSTANCE') as MY_USER_AND_SERVICE
  from dual
/