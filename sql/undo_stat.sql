--==============================================================================
-- Desc:   undo  stat
-- Source:
-- http://www.dbaref.com/home/dba-routine-tasks/scriptstocheckundotablespacestats
-- http://docs.oracle.com/cd/B28359_01/server.111/b28320/dynviews_3110.htm#REFRN30295
--==============================================================================
set verify  off
set linesize 120 pagesize 4000 recsep OFF



prompt -- How often and when does "Snapshot too old" (ORA-01555) occur?
prompt -- ----------------------------------------------------------------------- ---
prompt
Prompt -- Depending on the result: Increase the undo retention
prompt

select to_char(begin_time,'YYYY-MM-DD HH24:MI:SS') "Begin"
    ,  to_char(end_time,'YYYY-MM-DD HH24:MI:SS') "End "
	 ,  undoblks "UndoBlocks"
	 ,  SSOLDERRCNT "ORA-1555"
from V$UNDOSTAT
where SSOLDERRCNT > 0;

--length of the longest query (in seconds) 

Select max(MAXQUERYLEN) From V$UNDOSTAT;

prompt -- When and how often was the undo-tablespace too small?
prompt -- ----------------------------------------------------------------------- ---
prompt
Prompt -- Remedy: Making more space available for the undo-tablespace.
prompt

select to_char(begin_time,'YYYY-MM-DD HH24:MI:SS') "Begin",
to_char(end_time,'YYYY-MM-DD HH24:MI:SS') "End ",
undoblks "UndoBlocks",
nospaceerrcnt "Space Err"
from V$UNDOSTAT
where nospaceerrcnt > 0
/

