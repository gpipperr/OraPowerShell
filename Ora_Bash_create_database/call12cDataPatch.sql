define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA

set echo on

-- call datapatch >> 12C
-- done before on the shell script 
-- host $ORALCLE_HOME/OPatch/datapatch.bat -skip_upgrade_check -db $ORACLE_SID;

shutdown immediate;

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
startup

exit;

