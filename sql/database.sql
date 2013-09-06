--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Database information
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================


SET linesize 120 pagesize 400 recsep OFF


column inst_id   format 99  heading "Inst|Id"
column status    format A8  heading "Inst|Status"
column name      format A8  heading "DB|Name"
column created   format A16 heading "DB Create|Time"
column host_name format A18 heading "Inst Server|Name"
column edition   like host_name  heading "DB|Version"
column inst_name format A8  heading "Instance|Name"

column dbid      format A12 heading "Database|Id"

ttitle "Database Information" SKIP 2

SET UNDERLINE '='

select  v.inst_id
	  , v.instance_name as inst_name
	  , v.status
	  , v.host_name 
	  , to_char(d.dbid) as dbid
      , d.name
      , to_char(d.created,'dd.mm.yyyy hh24:mi') as created 
      , (select banner from v$version where banner like 'Oracle%') as edition
  from gv$database d
      ,gv$instance v
 where d.inst_id=v.inst_id	  
 order by v.instance_name 
/


ttitle "DB Log Mode" SKIP 2

select LOG_MODE from v$database;

archive log list


ttitle "MegaByte total DB Size for all files" SKIP 2

column mb_total format 999G999G999D00 heading "MegaByte total"

select round((a.data_size + b.temp_size + c.redo_size)/1024/1024,3) as  mb_total
from ( select sum(bytes) data_size        from dba_data_files ) a
	,( select nvl(sum(bytes),0) temp_size from dba_temp_files ) b
	,( select sum(bytes) redo_size         from sys.v_$log ) c
/

ttitle "MegaByte DB Objects in use" SKIP 2

column mb_obj format 999G999G999D00 heading "MegaByte DB Objects"

select round(sum(bytes)/1024/1024,3) as mb_obj 
  from dba_segments
/

SET UNDERLINE '-'

ttitle "Current SCN" SKIP 2

column current_scn format 99999999999999999999999999 

SELECT name
    , to_char(sysdate,'dd.mm.yyyy hh24:mi') 
    , current_scn 
FROM  v$database
/



ttitle off
