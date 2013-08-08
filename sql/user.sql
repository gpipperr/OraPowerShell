--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the user rights and grants
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

define USER_NAME = &1 

set verify off

SET linesize 120 pagesize 400 recsep OFF

ttitle left  "User Info" skip 2

select lpad(' ', 2 * level) || granted_role "User, his roles and privileges"
  from (
        /* THE USERS */
        select null     grantee
               ,username granted_role
          from dba_users
         where username like upper('&&USER_NAME.')
        /* THE ROLES TO ROLES RELATIONS */
        union
        select grantee
              ,granted_role
          from dba_role_privs
        /* THE ROLES TO PRIVILEGE RELATIONS */
        union
        select grantee
              ,privilege
          from dba_sys_privs)
 start with grantee is null
connect by grantee = prior granted_role
/

ttitle left  "Object rights from &&USER_NAME. to other User" skip 2

column grantee format a25
column GRANTOR format a25
column PRIVILEGE format a20
column cnt format 9999

select GRANTOR
      ,grantee
      ,PRIVILEGE
      ,table_name
      ,count(*) as cnt
  from DBA_TAB_PRIVS
 where owner like upper('&&USER_NAME.')
-- owner not in ('SYS','MDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','ORDDATA','ORDSYS','EXFSYS','XS$NULL','XDB','CTXSYS','WMSYS','APPQOSSYS','DBSNMP','ORACLE_OCM','DIP','OUTLN','SYSTEM','FLOWS_FILES','PUBLIC','SYSMAN','OLAPSYS','OWBSYS','OWBSYS_AUDIT')
 group by owner
         ,grantee
         ,GRANTOR
         ,PRIVILEGE
         ,table_name 
/

ttitle left  "Object rights from other User  to &&USER_NAME." skip 2

select GRANTOR
      ,grantee
      ,PRIVILEGE
      ,table_name
      ,count(*) as cnt
  from DBA_TAB_PRIVS
 where grantee like upper('&&USER_NAME.')
 group by owner
         ,grantee
         ,GRANTOR
         ,PRIVILEGE
         ,table_name
/


ttitle off
