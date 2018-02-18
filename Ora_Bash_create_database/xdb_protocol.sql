SET VERIFY ON

define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA

set echo on
spool $SCRIPTS/xdb_protocol.log append

SET VERIFY ON
@$ORACLE_HOME/rdbms/admin/catqm.sql change_on_install SYSAUX TEMP YES
--SET VERIFY off

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA

SET VERIFY OFF
@$ORACLE_HOME/rdbms/admin/catxdbj.sql
@$ORACLE_HOME/rdbms/admin/catrul.sql
SET VERIFY ON

spool off

exit
