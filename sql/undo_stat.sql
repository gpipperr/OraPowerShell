--==============================================================================
-- Desc:   undo  stat
-- Source:
-- http://www.dbaref.com/home/dba-routine-tasks/scriptstocheckundotablespacestats
-- http://docs.oracle.com/cd/B28359_01/server.111/b28320/dynviews_3110.htm#REFRN30295
--==============================================================================

set verify  off

set linesize 120 pagesize 4000 recsep OFF



prompt -- How often and when does "Snapshot too old" (ORA-01555) occur?
prompt --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt
Prompt -- Depending on the result: Increase the undo retention
prompt

select to_char(begin_time,'YYYY-MM-DD HH24:MI:SS') "Begin"
    ,  to_char(end_time,'YYYY-MM-DD HH24:MI:SS') "End "
	 ,  undoblks "UndoBlocks"
	 ,  SSOLDERRCNT "ORA-1555"
	 ,  MAXQUERYID
from V$UNDOSTAT
where SSOLDERRCNT > 0;


prompt --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt -- length of the longest query (in seconds) 

Select max(MAXQUERYLEN) From V$UNDOSTAT;

prompt -- When and how often was the undo-tablespace too small?
prompt --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt
Prompt -- Remedy: Making more space available for the undo-tablespace.
prompt

select to_char(begin_time,'YYYY-MM-DD HH24:MI:SS') "Begin"
	  , to_char(end_time,'YYYY-MM-DD HH24:MI:SS') "End "
	  , undoblks "UndoBlocks"
	  , nospaceerrcnt "Space Err"
 from V$UNDOSTAT
where nospaceerrcnt > 0
/


prompt -- Maximal Undo usage (MB) over the last 4 days
prompt --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt
-- http://docs.oracle.com/cd/E11882_01/server.112/e40402/dynviews_3118.htm#REFRN30295
-- thanks to may be trivadis ? 
--

column days    format a6       heading "day"
column m30    format 999999    heading "30m"
column m60    format 999999    heading "1h"
column m120   format 999999    heading "2h"
column m180   format 999999    heading "3h"
column m240   format 999999    heading "4h"
column m300   format 999999    heading "5h"
column m600   format 999999    heading "6h"
column m900   format 999999    heading "15"
column m1440  format 999999    heading "24h"
column m1800  format 999999    heading "30h"
column m2400  format 999999    heading "40h"
column m3000  format 999999    heading "50h"

select  days
		, round(b.block_size * a.m30  /(1024*1024)) m30
		, round(b.block_size * a.m60  /(1024*1024)) m60
		, round(b.block_size * a.m120 /(1024*1024)) m120
		, round(b.block_size * a.m180 /(1024*1024)) m180
		, round(b.block_size * a.m240 /(1024*1024)) m240
		, round(b.block_size * a.m300 /(1024*1024)) m300
		, round(b.block_size * a.m600 /(1024*1024)) m600
		, round(b.block_size * a.m900 /(1024*1024)) m900
		, round(b.block_size * a.m1440/(1024*1024)) m1440
		, round(b.block_size * a.m1800/(1024*1024)) m1800
		, round(b.block_size * a.m2400/(1024*1024)) m2400
		, round(b.block_size * a.m3000/(1024*1024)) m3000
from
  (select max(sum_blk30)    m30
			, max(sum_blk60)   m60
			, max(sum_blk120)  m120
			, max(sum_blk180)  m180
			, max(sum_blk240)  m240
			, max(sum_blk300)  m300
			, max(sum_blk600)  m600
			, max(sum_blk900)  m900
			, max(sum_blk1440) m1440
			, max(sum_blk1800) m1800
			, max(sum_blk2400) m2400
			, max(sum_blk3000) m3000		
			, days			
		from
			 (select  begin_time
					, undoblks
					, to_char(begin_time,'dd.mm') as days
					, sum(undoblks) over (order by begin_time rows between current row and 2 following)   as sum_blk30
					, sum(undoblks) over (order by begin_time rows between current row and 5 following)   as sum_blk60
					, sum(undoblks) over (order by begin_time rows between current row and 11 following)  as sum_blk120
					, sum(undoblks) over (order by begin_time rows between current row and 17 following)  as sum_blk180
					, sum(undoblks) over (order by begin_time rows between current row and 23 following)  as sum_blk240
					, sum(undoblks) over (order by begin_time rows between current row and 29 following)  as sum_blk300
					, sum(undoblks) over (order by begin_time rows between current row and 59 following)  as sum_blk600
					, sum(undoblks) over (order by begin_time rows between current row and 89 following)  as sum_blk900
					, sum(undoblks) over (order by begin_time rows between current row and 143 following) as sum_blk1440
					, sum(undoblks) over (order by begin_time rows between current row and 179 following) as sum_blk1800
					, sum(undoblks) over (order by begin_time rows between current row and 239 following) as sum_blk2400
					, sum(undoblks) over (order by begin_time rows between current row and 299 following) as sum_blk3000
			 from v$undostat
			order by begin_time )
		group by days	
	) a
, (select block_size  from dba_tablespaces  where contents='UNDO'    and status  ='ONLINE'  ) b 
order by days
/
 

