--==============================================================================
--
-- Desc:   Get the Redo Log scn information
-- Date:   01.November 2013
--
--==============================================================================
set linesize 130 pagesize 300 recsep off

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

ttitle  "Report LOGS with this SCN"  SKIP 1  - 


ACCEPT SCN prompt "search for SCN:"

column NAME      format a40    heading "Archivelog|Name"
column THREAD_NR format a2     heading "I"
column SEQUENCE# format 999999 heading "Arch|seq"

set NUMWIDTH  14

select to_char(THREAD#) as  THREAD_NR
     , SEQUENCE#
	  , NAME
	  , to_char(FIRST_TIME,'dd.mm hh24:mi') as first_time
	  , NEXT_TIME
	  , FIRST_CHANGE# 
	  , NEXT_CHANGE#
from v$archived_log 
where to_number('&&SCN.')  between  FIRST_CHANGE# and NEXT_CHANGE#
order by THREAD#,SEQUENCE#
/

undefine SCN