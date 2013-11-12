--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Recovery Area settings and size
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF

ttitle  "Report Recovery Dest Parameter"  SKIP 1 -
       center "Sizes in MB" SKIP 2


archive log list

	   
show parameter reco

column LIMIT format a10
column used  format a10
column RECLAIMABLE format a10
column NUMBER_OF_FILES  format a6 heading "Files"
column Used format a9
	   
select to_char(round(SPACE_LIMIT / 1024 / 1024, 2)) || 'M' as limit
      ,to_char(round(SPACE_USED / 1024 / 1024, 2)) || 'M' as used
      ,to_char(round(SPACE_RECLAIMABLE / 1024 / 1024, 2)) || 'M' as RECLAIMABLE
      ,to_char(NUMBER_OF_FILES) as NUMBER_OF_FILES
      ,to_char(round((SPACE_USED * 100) / SPACE_LIMIT, 2), '009D00') as Used
  from V$RECOVERY_FILE_DEST
/



ttitle off
