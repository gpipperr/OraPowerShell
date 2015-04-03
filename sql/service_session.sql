--==============================================================================
--
--==============================================================================

set verify off
set linesize 130 pagesize 300 recsep off


define OWNER    = '&1' 

prompt
prompt Parameter 1 = Owner Name => &&OWNER.
prompt

column inst_id       format 99 heading "SI"
column user_inst_id  format 99 heading "UI"
column username      format a16 heading "User|Name"
column machine       format a30 heading "Machine"
column service_name  format a20 heading "Service|Name"
column OSUSER        format a15 heading "OS|User"
column RESOURCE_CONSUMER_GROUP format a15   heading "Resource|Manager"
column session_count           format 9G999 heading "Sess|Cnt"
column status                  format a15   heading "Status"

BREAK ON inst_id skip 2
COMPUTE SUM OF session_count ON inst_id;


select  sv.inst_id 
		, sv.name as service_name
		, s.inst_id as user_inst_id
      , s.username
	   , s.machine		
		, s.OSUSER
	   , s.RESOURCE_CONSUMER_GROUP
		, status		
		, count(*)	as session_count	      
  from gv$session s
     , gv$active_services sv
where 
--s.service_name like 'S\_%' escape '\' 
 --'
 -- and 
 sv.name = s.service_name (+)
 and s.username not in ('SYS','DBSNMP')
 and upper(s.username)  like ('&&OWNER')
group by  s.username
		  , s.machine
		  , s.inst_id
		  , sv.name
		  , s.OSUSER
		  , s.RESOURCE_CONSUMER_GROUP
		  , sv.inst_id
        , status		  
 order by inst_id, service_name, username, status
/

