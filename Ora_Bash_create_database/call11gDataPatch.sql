define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
spool $SCRIPTS/postDBCreation.log append

SET VERIFY OFF
@$ORACLE_HOME/rdbms/admin/catbundle.sql psu apply
SET VERIFY  ON


select 'utl_recomp_begin: ' || to_char(sysdate, 'HH:MI:SS') from dual;

execute utl_recomp.recomp_serial();

select 'utl_recomp_end: ' || to_char(sysdate, 'HH:MI:SS') from dual;

shutdown immediate;

spool off

exit;
