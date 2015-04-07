--==============================================================================
-- GPI - Gunther Pippèrr
-- Desc:   show invalid objects in the database
-- Date:   01.September 2012
--
--==============================================================================
set linesize 130 pagesize 300 recsep off

ttitle center "Invalid Objects in the database" skip 2

column owner format a15
column object_type format a18

break on report
compute sum of anzahl on report

  select owner, object_type, count (*) as anzahl
    from all_objects
   where status != 'VALID'
--group by rollup(owner, object_type)
group by owner, object_type
/


clear breaks


ttitle "List of invalid indexes" skip 2

select owner
     ,  index_name
     ,  status
     ,  'no partition'
  from dba_indexes
 where status not in ('VALID', 'N/A')
union
select index_owner
     ,  index_name
     ,  status
     ,  partition_name
  from dba_ind_partitions
 where status not in ('VALID', 'N/A', 'USABLE')
/

ttitle "List of not validated or invalid constraints" skip 2

column owner                format a20
column table_name            format a30
column constraint_name     format a30
column validated             format a20

select owner
       ,  table_name
       ,  constraint_name
       ,  status
       ,  validated
    from dba_constraints
   where     (   validated != 'VALIDATED'
       or status != 'ENABLED')
     and owner not in
         ('SYS'
        ,  'MDSYS'
        ,  'SI_INFORMTN_SCHEMA'
        ,  'ORDPLUGINS'
        ,  'ORDDATA'
        ,  'ORDSYS'
        ,  'EXFSYS'
        ,  'XS$NULL'
        ,  'XDB'
        ,  'CTXSYS'
        ,  'WMSYS'
        ,  'APPQOSSYS'
        ,  'DBSNMP'
        ,  'ORACLE_OCM'
        ,  'DIP'
        ,  'OUTLN'
        ,  'SYSTEM'
        ,  'FLOWS_FILES'
        ,  'PUBLIC'
        ,  'SYSMAN'
        ,  'OLAPSYS'
        ,  'OWBSYS'
        ,  'OWBSYS_AUDIT')
order by owner
/


ttitle "List of invalid Objects" skip 2
break on owner skip 2
column owner noprint

  select object_type || '-> ' || decode (owner, 'PUBLIC', '', owner || '.') || object_name as Overview, owner
    from all_objects
   where status != 'VALID'
order by owner
/

clear breaks
column owner print

ttitle "command to touch the  Objects" skip 2

select 'desc ' || decode (owner, 'PUBLIC', '', owner || '.') || object_name as TOUCH_ME
  from all_objects
 where status != 'VALID'
/

--ttitle "delete Script for invalid synonym - synonym points on an not existing object" SKIP 2

--select 'drop ' || decode(s.owner, 'PUBLIC', 'PUBLIC SYNONYM ', 'SYNONYM ' || s.owner || '.') || s.synonym_name || ';' as DELETE_ME
--  from dba_synonyms s
-- where table_owner not in ('SYSTEM', 'SYS')
--   and (db_link is null or db_link = 'PUBLIC')
--   and not exists (select 1
--          from dba_objects o
--         where decode(s.table_owner, 'PUBLIC', o.owner, s.table_owner) = o.owner
--           and s.table_name = o.object_name);
--
ttitle off