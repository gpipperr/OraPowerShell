define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
spool $SCRIPTS/CreateClustDBViews.log append

SET VERIFY OFF
@?/rdbms/admin/catclust.sql;
SET VERIFY ON

spool off

exit
