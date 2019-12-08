define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA

spool $SCRIPTS/postDBCreation.log append

startup mount pfile="$SCRIPTS/init.ora";

alter database archivelog;
alter database open;

archive log list

spool off

exit;
