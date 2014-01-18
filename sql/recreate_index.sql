--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   index recreate script
-- Date:   First Version 2008
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set heading off
set feedback off
set pagesize 0
set linesize 130

define USER_NAME='&1'

prompt
prompt Parameter 1 = User Name          => &&USER_NAME.
prompt

-----------------------------
-- How many parallel jobs?
define PARALLEL_EXEC=32


-----------------------------
-- use instance default = default
-- to be on the save side use 1
define DEF_DEGREE='1'


-------------------
-- create spool name

col SPOOL_NAME_COL new_val SPOOL_NAME
 
SELECT replace(ora_database_name||'_'||SYS_CONTEXT('USERENV','HOST')||'_'||to_char(sysdate,'dd_mm_yyyy_hh24_mi')||'_index_rebuild_&&USER_NAME..sql','\','_') 
--' resolve syntax highlight bug FROM my editer .-(
  AS SPOOL_NAME_COL
FROM dual
/

-- get sum of database
ttitle "MegaByte DB Objects in use" SKIP 2

column mb_obj format 999G999G999D00 heading "MegaByte DB Objects"

select round(sum(bytes)/1024/1024,3) as mb_obj 
  from dba_segments
/

ttitle off


-- get sum size of all indexes

ttitle "MegaByte DB Objects in use" SKIP 2

column mb_obj format 999G999G999D00 heading "MegaByte DB Indexes"

select round(sum(bytes)/1024/1024,3) as mb_obj 
  from dba_segments
 where segment_type='INDEX'
  and owner = upper('&&USER_NAME.')
/

ttitle off

spool &&SPOOL_NAME

prompt 
prompt spool recreate_idx_inst_1.sql

prompt set echo on
prompt set timing on

prompt ttitle "MegaByte DB Index for the change in Use" SKIP 2
prompt 
prompt column mb_obj format 999G999G999D00 heading "MegaByte DB Indexes"
prompt 
prompt select round(sum(bytes)/1024/1024,3) as mb_obj 
prompt   from dba_segments
prompt  where segment_type='INDEX'
prompt   and owner = upper('&&USER_NAME.')
prompt /
prompt 
prompt ttitle off

select 'select to_char(sysdate,''hh24:mi'') from dual;'||chr(13)||chr(10)||'prompt rebuild the '||rownum||' index '||iname||' for table '||itabname||' ('||isize ||' MB)'||chr(13)||chr(10)||'alter index &&USER_NAME..' ||iname||' REBUILD PARALLEL &&PARALLEL_EXEC.  NOLOGGING;'||chr(13)||chr(10)||'alter index &&USER_NAME.' ||iname||' LOGGING PARALLEL (DEGREE &&DEF_DEGREE. instances default);'
from (
select i.index_name  iname
     , round (s.bytes / 1024 / 1024, 2) isize
     ,i.TABLE_NAME itabname
  from all_indexes i, dba_segments s
 where i.owner = upper('&&USER_NAME.')
   and i.index_type = 'NORMAL'
   and s.owner = i.owner
   and s.segment_name = i.index_name   
	and i.index_name not in (select ip.index_name from DBA_IND_PARTITIONS ip  where ip.INDEX_OWNER=i.owner)
)
order by itabname desc,isize asc

/

prompt ttitle "MegaByte DB Index after the change in Use" SKIP 2
prompt 
prompt column mb_obj format 999G999G999D00 heading "MegaByte DB Indexes"
prompt 
prompt select round(sum(bytes)/1024/1024,3) as mb_obj 
prompt   from dba_segments
prompt  where segment_type='INDEX'
prompt   and owner = upper('&&USER_NAME.')
prompt /
prompt 
prompt ttitle off

prompt spool off

spool off 

prompt to start start the recreate scripts start spool  &&SPOOL_NAME

set heading on
set feedback on

 
