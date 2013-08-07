define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on

spool $SCRIPTS/context.log append
SET VERIFY ON

@$ORACLE_HOME/ctx/admin/catctx change_on_install SYSAUX TEMP NOLOCK
--SET VERIFY ON

connect "CTXSYS"/"change_on_install"

--SET VERIFY OFF
@$ORACLE_HOME/ctx/admin/defaults/dr0defin.sql "AMERICAN"

SET VERIFY OFF

spool off

exit
