--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Informations about cursor usage in the database
-- Date:   08.2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 120 pagesize 400 recsep OFF

column user_name format a25

ttitle left  "Open Cursor used summary" skip 2

select inst_id
	  , user_name
     , count(*)
 from gv$open_cursor 
where user_name not in ( 'SYS' )  and user_name is not null
group by rollup (inst_id,user_name)
/

ttitle left  "Open Cursor used by session" skip 2
select inst_id
     , sid	
	  , user_name	
     , count(*)
 from gv$open_cursor 
where user_name not in ( 'SYS' ) and user_name is not null
group by inst_id,user_name,sid
order by 4,1,3
/

column name  format a30 heading "Statistic|Name"
column value format 999G999G999G999 heading "Statistic|value"


ttitle left  "Open Cursor used by session over the statistic" skip 2

select  a.value
      , s.username
		, s.sid
		, s.serial# 
from v$sesstat a
   , v$statname b
	, v$session s 
where a.statistic# = b.statistic#  
  and s.sid=a.sid 
  and b.name = 'opened cursors current'
 /


ttitle left  "Open Cursor Statistic " skip 2


select inst_id,cursor_hits,parse_count,cursor_hits/(parse_count/100) as hit_percentage from 
		( select name
			   , value
			   , inst_id
		 from gv$sysstat
		where name in ('session cursor cache hits','parse count (total)')		
		)
		pivot ( 
			   max (value)
				 FOR name
				 IN  (  'session cursor cache hits' AS cursor_hits
					  , 'parse count (total)' as parse_count
				)
		)
/

prompt ... 11g Syntax if you hid an error on 10g!
prompt ... if hit_percentage is a relatively low percentage of parse_count
prompt ... you should increate the DB Parameter session_cached_cursors

ttitle left  "Cursor Settings init.ora " skip 2
show parameter cursor

ttitle off