define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo off

spool $SCRIPTS/dbConsole.log append

---------------------------------------------------------------
-- enable Database Express Console at 12c
-- check dispatcher and local listener parameter
exec dbms_xdb_config.sethttpsport (5500);
---------------------------------------------------------------

WHENEVER SQLERROR CONTINUE;

spool off
exit

