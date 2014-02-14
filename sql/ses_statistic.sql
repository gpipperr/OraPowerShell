-------------------
-- in work
-------------------

select n.name
     , s.value
	 , ses.username
	 , ses.program
	 , ses.osuser
	 , ses.machine
from v$statname n
   , v$sesstat s
   , v$session ses
where n.statistic# = s.statistic# 
  and s.sid = ses.sid 
  and s.statistic# not in (13, 14)
order by value desc
/