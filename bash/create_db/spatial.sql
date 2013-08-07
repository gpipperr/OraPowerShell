define SYSUSER_PWD='&1'
connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
spool $SCRIPTS/spatial.log append

SET VERIFY OFF
@$ORACLE_HOME/md/admin/mdinst.sql
SET VERIFY ON

spool off

exit
