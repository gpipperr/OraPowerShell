define SYSUSER_PWD='&1'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA

set echo on

alter user SYSMAN account unlock;
alter user DBSNMP account unlock

set echo off

exit;
