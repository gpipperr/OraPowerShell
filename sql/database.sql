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
 order by v.instance_name 
/

SET UNDERLINE '-'

archive log list

ttitle "Current SCN" SKIP 2

SELECT name
    , to_char(sysdate,'dd.mm.yyyy hh24:mi') 
    , current_scn 
FROM  v$database
/

ttitle off
