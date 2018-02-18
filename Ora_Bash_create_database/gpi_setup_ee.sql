define SYSUSER_PWD='&1'
define tracking_file='&2'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
spool $SCRIPTS/gpi_setup.log append

-- enable block change Tracking
ALTER DATABASE ENABLE BLOCK CHANGE TRACKING USING FILE '&&tracking_file';

spool off

exit
