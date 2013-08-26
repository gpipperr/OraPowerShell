--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   show invaild objects in the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

ttitle center "Invaild Objects in the database" SKIP 2
 
column owner format a10
column object_type format a14
 
select owner
      ,object_type
      ,count(*) as anzahl
  from all_objects
 where status != 'VALID'
 group by rollup(owner, object_type)
/

ttitle "List of invalid indexes" SKIP 2

select owner
      ,index_name
      ,status
      ,'no partition'
  from dba_indexes
 where status not in ('VALID', 'N/A')
union
select index_owner
      ,index_name
      ,status
      ,partition_name
  from dba_ind_partitions
 where status not in ('VALID', 'N/A', 'USABLE')
/

ttitle "List of invalid Objects" SKIP 2

select object_type|| '-> ' || decode(owner, 'PUBLIC', '', owner || '.') || object_name as TOUCH_ME
  from all_objects
 where status != 'VALID'
order by object_type
/

ttitle "command to touch the  Objects" SKIP 2

select 'desc ' || decode(owner, 'PUBLIC', '', owner || '.') || object_name as TOUCH_ME
  from all_objects
 where status != 'VALID'
/
 
ttitle "delete Script for invalid synonym - synonym points on an not existing object" SKIP 2

select 'drop ' || decode(s.owner, 'PUBLIC', 'PUBLIC SYNONYM ', 'SYNONYM ' || s.owner || '.') || s.synonym_name || ';' as DELETE_ME
  from dba_synonyms s
 where table_owner not in ('SYSTEM', 'SYS')
   and (db_link is null or db_link = 'PUBLIC')
   and not exists (select 1
          from dba_objects o
         where decode(s.table_owner, 'PUBLIC', o.owner, s.table_owner) = o.owner
           and s.table_name = o.object_name);

ttitle off
