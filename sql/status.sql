--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Status all Instances
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================


ttitle left  "Status all Instances" skip 2

column inst_id   format 9   heading "Inst|Id"
column status    format A8  heading "Status"
column name      format A8  heading "Instance|Name"
column startzeit format A15 heading "Start|Time"
column host_name format A25 heading "Server|Name"

select inst_id
      ,status
      ,instance_name as name
      ,to_char(STARTUP_TIME, 'dd.mm.YY hh24:mi') as startzeit
	  ,host_name 
  from gv$instance
 order by 1
/

ttitle off

