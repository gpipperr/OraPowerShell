define SYSUSER_PWD='&1'
define ORACLE_HOME='&2'
define SYSMAN_USER_PWD='&3'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo off
spool $SCRIPTS/emRepository.log append

@$ORACLE_HOME/sysman/admin/emdrep/sql/emreposcre &&ORACLE_HOME SYSMAN &&SYSMAN_USER_PWD TEMP ON

WHENEVER SQLERROR CONTINUE;

spool off
exit
