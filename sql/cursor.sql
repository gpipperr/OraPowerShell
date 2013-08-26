--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Informations about cursor usage in the database
-- Date:   08.2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 120 pagesize 400 recsep OFF

ttitle left  "Open Cursor used " skip 2

select inst_id
	, user_name
    , count(*)
 from gv$open_cursor 
where user_name not in ( 'SYS' ) 
group by rollup (inst_id,user_name)
/

ttitle left  "Open Cursor used " skip 2
select inst_id
	, user_name
	, sid
    , count(*)
 from gv$open_cursor 
where user_name not in ( 'SYS' ) 
group by inst_id,user_name,sid
order by inst_id,user_name
/

ttitle left  "Open Cursor Statistic " skip 2
column name  format a30 heading "Statistic|Name"
column value format 999G999G999G999 heading "Statistic|value"

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