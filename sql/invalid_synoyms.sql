--==============================================================================
-- GPI - Gunther Pippèrr
-- Desc:   show invalid synonyms in the database and create delete script
-- Date:   01.Oktober 2015
--
--==============================================================================
set linesize 130 pagesize 300 recsep off


ttitle center "Count of synonyms without an existing owner in the database" skip 2


break on report
compute sum of anzahl on report

select count(*) as anzahl
     ,  table_owner 
  from dba_synonyms 
where table_owner not in (select username from dba_users) group  by table_owner;

clear breaks
 
ttitle center "Invalid synonyms in the database" skip 2

column owner format a15
column table_owner format a15

select decode(s.owner, 'PUBLIC', 'PUBLIC SYNONYM ', 'SYNONYM ') as SYN_TYPE, s.owner, s.synonym_name, '=>>', s.table_owner, s.table_name
 from dba_synonyms s
where table_owner not in ('SYSTEM', 'SYS')
  and (db_link is null or db_link = 'PUBLIC')
  and not exists (select 1
         from dba_objects o
        where decode(s.table_owner, 'PUBLIC', o.owner, s.table_owner) = o.owner
          and s.table_name = o.object_name)
/
	
ttitle center "Delete Script" skip 2	

select 'drop ' || decode(s.owner, 'PUBLIC', 'PUBLIC SYNONYM ', 'SYNONYM ' || s.owner || '.') || s.synonym_name || ';' as DELETE_ME
 from dba_synonyms s
where table_owner not in ('SYSTEM', 'SYS')
  and (db_link is null or db_link = 'PUBLIC')
  and not exists (select 1
         from dba_objects o
        where decode(s.table_owner, 'PUBLIC', o.owner, s.table_owner) = o.owner
          and s.table_name = o.object_name)
/		  

ttitle off
