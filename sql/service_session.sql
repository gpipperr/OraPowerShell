-------------------
-- in work
-------------------

set pagesize 300
set linesize 140
set recsep off

define service_name_filter='S_'

column inst_id       format 99 heading "In"
column username      format a20 heading "User|Name"
column machine       format a20 heading "Machine"
column service_name  format a20 heading "Service|Name"

select  sv.inst_id
		, sv.name as service_name
      , s.username
		, s.machine		
		, count(*)		
  from gv$session s
     , gv$active_services sv
where regexp_like(s.service_name,'&&service_name_filter.')
  and sv.name = s.service_name (+)
group by  s.username
		  , s.machine
		  , sv.name
		  , sv.inst_id
 order by 1, 2, 3, 4
/


