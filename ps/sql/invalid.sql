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
          ,count(*)  as anzahl
from all_objects 
where status!='VALID' 
group by rollup (owner,object_type)
/
ttitle off

prompt "List of invalid indexes"

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
 where status not in ('VALID', 'N/A','USABLE')
/


ttitle off
prompt "List of invalid Objects"
select 'desc '||decode (owner,'PUBLIC','',owner||'.')||object_name as TOUCH_ME
  from all_objects 
where status!='VALID' 
/
 
prompt "delete Script for invalid synonym - synonym points on an not existing object"
SELECT 'drop '||decode (s.owner,'PUBLIC','PUBLIC SYNONYM ','SYNONYM '||s.owner||'.')||s.synonym_name||';'  as DELETE_ME
FROM dba_synonyms  s
WHERE table_owner NOT IN('SYSTEM','SYS')
  AND( db_link IS NULL or db_link ='PUBLIC')
  AND NOT EXISTS
     (SELECT  1
      FROM dba_objects o
      WHERE decode (s.table_owner,'PUBLIC',o.owner,s.table_owner)=o.owner
      AND s.table_name=o.object_name);
