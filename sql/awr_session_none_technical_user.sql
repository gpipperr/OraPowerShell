--==============================================================================
--
-- Desc: get a report over the user activities ( for example sqlplus.exe or toad.exe ) of the last day
--   
--==============================================================================

SET pagesize 1000
SET linesize 130

define timing= 1800


column username        format a10
column SAMPLE_TIME     format a18
column PROGRAM         format a16
column MODULE          format a16
column ACTION          format a16
column CLIENT_ID       format a16
column MACHINE		     format a16
column service_name    format a16

ttitle "Summary of all user sessions from none technical users "   skip 2

select count(*)
      ,u.username
      ,ah.PROGRAM
		,ah.MODULE
		,ah.ACTION
		,ah.CLIENT_ID
		,ah.MACHINE		
		,ass.name as service_name
  from GV$ACTIVE_SESSION_HISTORY ah
      ,GV$ACTIVE_SERVICES        ass
      ,dba_users                 u
 where ass.inst_id = ah.inst_id
   and ass.NAME_HASH = ah.SERVICE_HASH
   and u.user_id = ah.user_id
   and ah.SAMPLE_TIME > (sysdate - ((1 / (24 * 60)) * &&timing. ))
	-- filter for all none prod program like *.exe
	and ( ah.program like '%.exe' 
	      or 
		   ah.program like '%plus%' 
	)
	--
	and u.username not in ('DBSNMP','HP_DBSPI') 
 group by u.username
      ,ah.PROGRAM
		,ah.MODULE
		,ah.ACTION
		,ah.CLIENT_ID
		,ah.MACHINE		
		,ass.name
 --having count(*) > 25 * 60
 order by username desc
/ 

ttitle off



