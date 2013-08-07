define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA

set echo on
spool $SCRIPTS/interMedia.log append

SET VERIFY OFF
@$ORACLE_HOME/ord/im/admin/iminst.sql
SET VERIFY ON

spool off

exit
