define SYSUSER_PWD='&1'
set echo on
spool $SCRIPTS/cwmlite.log append

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA

SET VERIFY OFF
@$ORACLE_HOME/olap/admin/olap.sql SYSAUX TEMP
SET VERIFY ON

spool off

exit

