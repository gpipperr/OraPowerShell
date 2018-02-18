define SYSUSER_PWD='&1'
define SPFILE_LOCATION='&2'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
create spfile='&&SPFILE_LOCATION' FROM pfile='$SCRIPTS/init.ora';
shutdown immediate;

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
startup

exit;