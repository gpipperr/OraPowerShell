------------------

set pagesize 300
set linesize 140
set recsep off


column inst_id       format 99 heading "In"
column username      format a17 heading "User|Name"
column machine       format a30 heading "Machine"
column service_name  format a20 heading "Service|Name"
column OSUSER        format a15 heading "OS|User"
column RESOURCE_CONSUMER_GROUP format a15  heading "Resource|Manager"
column session_count           format 9999 heading "Sess|Cnt"
column status                  format a15 heading "Status"


select  sv.inst_id
		, sv.name as service_name
      , s.username
	   , s.machine		
		, s.OSUSER
		, s.RESOURCE_CONSUMER_GROUP
		, status		
		, count(*)	as session_count	      
  from gv$session s
     , gv$active_services sv
where s.service_name like 'S\_%' escape '\' 
 --'
  and sv.name = s.service_name (+)
  and s.username not in ('LPDBA')
group by  s.username
		  , s.machine
		  , sv.name
		  , s.OSUSER
		  , s.RESOURCE_CONSUMER_GROUP
		  , sv.inst_id
        , status		  
 order by 1, 2, 3, 4
/

