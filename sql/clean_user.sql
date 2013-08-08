-- 
-- clean_user.sql
-- Script to create a sql script to clean Oracle schema from the user objects
-- Parameter 1: Name of the User 
--
-- Must be run with dba privileges
-- 


set verify  off
set linesize 120 pagesize 4000 recsep OFF

define USER_NAME = &1 

col SPOOL_NAME_COL new_val SPOOL_NAME

prompt ==================== SQL Script Name =========================
column SPOOL_NAME_COL format a60

select replace(ora_database_name || '_' || SYS_CONTEXT('USERENV', 'HOST') || '_' ||
                to_char(sysdate, 'dd_mm_yyyy_hh24_mi') || '_drop_&&USER_NAME..sql', '\', '_')
       --' resolve syntax highlight bug FROM my editor .-(
        as SPOOL_NAME_COL
  from dual
/

prompt
prompt ==================== User Objects Overview ===================
prompt
select owner
      ,obj_type
      ,obj_count
  from (select count(*) as obj_count
              ,object_type as obj_type
              ,owner
          from dba_objects
         group by object_type
                 ,owner)
 where upper(owner) in (upper('&&USER_NAME.'))
-- info line for copy/past  if you need statment to check all app. users in den database
--owner not in ('SYS','MDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','ORDDATA','ORDSYS','EXFSYS','XS$NULL','XDB','CTXSYS','WMSYS','APPQOSSYS','DBSNMP','ORACLE_OCM','DIP','OUTLN','SYSTEM','FLOWS_FILES','PUBLIC','SYSMAN','OLAPSYS','OWBSYS','OWBSYS_AUDIT')
 group by owner
         ,obj_type
         ,obj_count
 order by owner
         ,obj_type
/

prompt
prompt ==================== Create Delete Script ====================
prompt

set feedback off
set heading off

spool &&SPOOL_NAME

prompt set echo on
prompt spool &&SPOOL_NAME.log


-- drop all queue of the user

select 'EXECUTE DBMS_AQADM.STOP_QUEUE ( queue_name => ''' || q.owner || '.' || q.name || ''');'
  from DBA_QUEUES q
 where upper(q.owner) in (upper('&&USER_NAME.'))
/

select 'EXECUTE DBMS_AQADM.DROP_QUEUE ( queue_name => ''' || q.owner || '.' || q.name || ''');'
  from DBA_QUEUES q
 where upper(q.owner) in (upper('&&USER_NAME.'))
/

select 'EXECUTE  DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table => ''' || q.owner || '.' || q.QUEUE_TABLE ||
       ''',  force => true);'
  from DBA_QUEUES q
 where upper(q.owner) in (upper('&&USER_NAME.'))
/

-- drop XML Schema definitions from this user + XML Tables 
-- not tested yet!
select 'execute  DBMS_XMLSCHEMA.deleteSchema(SCHEMAURL => ''' || x.SCHEMA_URL ||
       ''',DELETE_OPTION => dbms_xmlschema.DELETE_CASCADE_FORCE);'
  from DBA_XML_SCHEMAS x
 where upper(x.owner) in (upper('&&USER_NAME.'))
/

-- drop table constraints
-- to avoid FK Contraint Errors!
select 'alter table ' || c.OWNER || '.' || c.TABLE_NAME || ' drop CONSTRAINT ' || c.CONSTRAINT_NAME || ';'
  from DBA_CONSTRAINTS c
 where c.CONSTRAINT_TYPE in ('R', 'U')
   and not exists (select 1
          from DBA_CONSTRAINTS i
         where i.OWNER = c.owner
           and i.TABLE_NAME = c.TABLE_NAME
           and i.CONSTRAINT_NAME = c.CONSTRAINT_NAME
           and c.CONSTRAINT_TYPE = 'P')
   and upper(c.owner) in (upper('&&USER_NAME.'))
/ 

-- drop all indexes
-- May be unnecessary  - will be dropped also with the table

select 'drop index ' || i.owner || '.' || i.index_name || ';'
  from dba_indexes i
 where i.index_type not in ('LOB')
   and i.table_name not in (select q.QUEUE_TABLE from DBA_QUEUES q where q.owner = i.owner)
   and i.index_name not in (select ii.index_name
                              from DBA_CONSTRAINTS ii
                             where ii.OWNER = i.owner
                               and ii.TABLE_NAME = i.TABLE_NAME
                               and ii.CONSTRAINT_TYPE not in ('P'))
   and upper(i.owner) in (upper('&&USER_NAME.'))
/ 

-- drop all other objects in the right order

select 'drop ' || o.object_type || ' ' || o.owner || '.' || object_name || ' ' ||
       decode(o.object_type, 'TABLE', 'PURGE', '') || ';' as command
  from dba_objects o
 where o.object_type in
       ('SEQUENCE', 'JAVA DATA', 'PROCEDURE', 'PACKAGE', 'PACKAGE BODY', 'TYPE BODY', 'JAVA RESOURCE', 'DIRECTORY',
        'TABLE', 'SYNONYM', 'VIEW', 'FUNCTION', 'JAVA CLASS', 'JAVA SOURCE', 'TYPE')
   and upper(o.owner) in (upper('&&USER_NAME.'))
   and o.object_name not in (select q.QUEUE_TABLE from DBA_QUEUES q where q.owner = o.owner)
order by decode (o.object_type
					,'SEQUENCE',20
					,'JAVA DATA',10
					,'PROCEDURE',21
					,'PACKAGE',24
					,'PACKAGE BODY',23
					,'TYPE BODY',41
					,'JAVA RESOURCE',11
					,'DIRECTORY',80
					,'TABLE',35
					,'SYNONYM',40
					,'VIEW',20
					,'FUNCTION',22
					,'JAVA CLASS',11
					,'JAVA SOURCE',12
					,'TYPE',42
					,99)
/

prompt -- !Attention
prompt -- delete the ALL RECYCLEBIN's in the database
prompt -- please comment if you don't like it 
prompt PURGE DBA_RECYCLEBIN;
--
prompt  spool off
prompt  exit

spool off
set heading on
set verify on

prompt
prompt ==================== Finish Delete Script ====================
prompt ==
prompt == to drop the objects of the user &&USER_NAME.
prompt == call the script:
prompt == &&SPOOL_NAME 
prompt == and check the log file for the results
prompt == &&SPOOL_NAME.log 
prompt ==
prompt ============================================================== 

