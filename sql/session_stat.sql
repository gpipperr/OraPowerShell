--==============================================================================
-- get statistics from running session for this sql

--==============================================================================
set linesize 130 pagesize 300 recsep off

ttitle  "Report sessions waits"  SKIP 2 

column client_info  format a30
column MODULE       format a20
column username     format a10 heading "User|name"

column program      format a20
column state        format a20
column event        format a15
column last_sql     format a20
column sec          format 99999 heading "Wait|sec"
column inst         format 9     heading "Inst"
column ss           format a10 heading "SID:Ser#"
column name         format a30

break on ss

select inst
     , ss
	  , username
	  , name
	  , value
	  , round((ratio_to_report( SUM( value )) OVER(PARTITION BY ss) )*100,3) AS prozent
from (
select /* gpi script lib session_stat.sql */
       sw.inst_id as inst
      , s.sid || ',' || s.serial# as ss
    --, s.client_info
    --, s.MODULE
      , s.username
    --, s.program
      , sn.name
      , sw.value
  from gv$sesstat sw
    	,v$statname sn
      ,gv$session  s      
 where sw.STATISTIC# = sn.STATISTIC#
   and sn.NAME in ('table fetch continued row','table fetch by rowid' )   
	--
	and sw.inst_id = s.inst_id    
	and sw.sid = s.sid
	--
   and s.sql_id='bzp2cjztj8yb7'
	)
group by inst,ss,username,name,value
order by inst,ss 
/

clear break

ttitle off
