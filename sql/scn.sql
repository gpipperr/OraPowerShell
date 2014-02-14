--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Get the Redo Log scn information
-- Date:   01.November 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF

SET SERVEROUTPUT ON SIZE 1000000

prompt 

DECLARE
  v_scn NUMBER;
BEGIN
  v_scn:= DBMS_FLASHBACK.GET_SYSTEM_CHANGE_NUMBER;
  DBMS_OUTPUT.PUT_LINE('current SCN: ' || v_scn);
END;
/


ttitle  "Report Redo Log SCN History per Day"  SKIP 1  - 

column min_scn format 999999999999999
column max_scn format 999999999999999
			 
select 
       trunc(FIRST_TIME) as days
	  , thread#
     , min(FIRST_CHANGE#) as min_scn
     , max(FIRST_CHANGE#) as max_scn
	  , count(*)       as archive_count		  
 from V$LOG_HISTORY 
where FIRST_TIME > trunc(sysdate - 14)
group by trunc(FIRST_TIME),thread#
order by 1,2
/

ttitle off

