define SYSUSER_PWD='&1'
define SYSTEMUSER_PWD='&2'


connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
spool $SCRIPTS/CreateDBCatalog.log append


SET VERIFY OFF
@$ORACLE_HOME/rdbms/admin/catalog.sql
@$ORACLE_HOME/rdbms/admin/catblock.sql
@$ORACLE_HOME/rdbms/admin/catproc.sql
@$ORACLE_HOME/rdbms/admin/catoctk.sql
@$ORACLE_HOME/rdbms/admin/owminst.plb
SET VERIFY ON

spool off

------- SQL PLUS 

connect "SYSTEM"/"&&SYSTEMUSER_PWD"

spool $SCRIPTS/sqlPlusHelp.log append

SET VERIFY OFF
@$ORACLE_HOME/sqlplus/admin/pupbld.sql
@$ORACLE_HOME/sqlplus/admin/pupdel.sql
SET VERIFY ON

connect "SYSTEM"/"&&SYSTEMUSER_PWD"
set echo on

SET VERIFY OFF
@$ORACLE_HOME/sqlplus/admin/help/hlpbld.sql helpus.sql
SET VERIFY ON

spool off

exit

