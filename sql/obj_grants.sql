--desc DBA_ROLE_PRIVS
--desc DBA_SYS_PRIVS
--desc DBA_TAB_PRIVS


SET pagesize 300
SET linesize 250
SET VERIFY OFF

define OWNER    = '&1' 
define TAB_NAME = '&2' 

prompt
prompt Parameter 1 = Owner Name => &&OWNER.
prompt Parameter 2 = Tab Name   => &&TAB_NAME.
prompt

ttitle left  "Grants the object &OWNER..&TAB_NAME." skip 2

column GRANTEE     format a20
column OWNER       format a20
column TABLE_NAME  format a20
column GRANTOR     format a20
column PRIVILEGE   format a20


select  GRANTEE
		, OWNER
		, TABLE_NAME
		, GRANTOR
		, PRIVILEGE
--		, GRANTABLE
--		, HIERARCHY
  from dba_tab_privs 
 where owner = upper('&OWNER')   
   and table_name = upper('&TAB_NAME')
/

ttitle off


