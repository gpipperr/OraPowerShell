--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Informations about sga usage in the database
-- Date:   08.2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 120 pagesize 400 recsep OFF

-- sga infos

ttitle left  "SGA Pools" skip 2

show sga


ttitle left  "SGA Advisory" skip 2

select * from v$sga_target_advice order by 1;


ttitle left  "Library Cache hits" skip 2

select sum(pins) "hits"
     , sum(reloads) "misses"
	 , round((sum(pins)/(sum(reloads)+sum(pins)))*100, 2) "hit ratio, %"
from v$librarycache
/


ttitle left  "Buffer Cache hit statistic" skip 2

select round((1-(pr.value/(bg.value+cg.value)))*100,2) "Buffer Cache Hit Ratio"
 from v$sysstat pr
     ,  v$sysstat bg
	 , v$sysstat cg
where pr.name='physical reads'
  and bg.name='db block gets'
  and cg.name='consistent gets'
/

ttitle off