--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   check the TAF - Transparent Applicatoin Failover Connects to a database
-- Site:   http://orapowershell.codeplex.com
--==============================================================================


SET linesize 140 pagesize 300 recsep OFF

column inst_id    format 99       heading "Inst|ID"
column username   format a14      heading "DB User|name"
column machine    format a36      heading "Remote|pc/server"
column connect_count   format 9G999 heading "Con|count"
column failover_type   format a6    heading "Fail|type"
column failover_method format a6    heading "Fail|method"
column failed_over     format a6    heading "Fail|over"

select inst_id
      , machine
	  , username
      , failover_type
	  , failover_method
	  , failed_over
	  , count(*) as connect_count
 from gv$session
where username is not null 
group by inst_id,machine, username,failover_type, failover_method, failed_over
order by machine
/
