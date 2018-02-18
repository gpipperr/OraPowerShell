define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
spool $SCRIPTS/JServer.log append

SET VERIFY OFF
@$ORACLE_HOME/javavm/install/initjvm.sql
@$ORACLE_HOME/xdk/admin/initxml.sql
@$ORACLE_HOME/xdk/admin/xmlja.sql
@$ORACLE_HOME/rdbms/admin/catjava.sql
@$ORACLE_HOME/rdbms/admin/catexf.sql
SET VERIFY ON

spool off

exit
