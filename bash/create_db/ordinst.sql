define SYSUSER_PWD='&1'
connect "SYS"/"&&SYSUSER_PWD" as SYSDBA

set echo on
spool $SCRIPTS/ordinst.log append

SET VERIFY OFF
@$ORACLE_HOME/ord/admin/ordinst.sql SYSAUX SYSAUX
SET VERIFY ON

spool off

exit
