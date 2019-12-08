define SYSUSER_PWD='&1'
define SPFILE_LOCATION='&2'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
create spfile='&&SPFILE_LOCATION' FROM pfile='$SCRIPTS/init.ora';
shutdown immediate;

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
startup

select 'utlrp_begin: ' || to_char(sysdate, 'HH:MI:SS') from dual;

@$ORACLE_HOME/rdbms/admin/utlrp.sql;

select 'utlrp_end: ' || to_char(sysdate, 'HH:MI:SS') from dual;

select comp_id, status from dba_registry;

exit;
