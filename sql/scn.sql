--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Get the Redo Log scn information
-- Date:   01.November 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF

ttitle  "Report Redo Log SCN History per Day"  SKIP 1  - 
			 
select 
       trunc(FIRST_TIME) as days
	  , thread#
     , min(SEQUENCE#) as min_scn
     , max(SEQUENCE#) as max_scn
	  , count(*)       as archive_count		  
 from V$LOG_HISTORY 
where FIRST_TIME > trunc(sysdate - 14)
group by trunc(FIRST_TIME),thread#
order by 1,2
/
