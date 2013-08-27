--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   check Services and tns Settings for the services
-- Date:   09.2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set pagesize 300
set linesize 140
set recsep off


ttitle 'services configured to use load balancing advisory (lba) features| (from dba_services)'

column name            format a16      heading 'service name' wrap
column created_on      format a20      heading 'created on' wrap
column goal            format a12      heading 'service|workload|management|goal'
column clb_goal        format a12      heading 'connection|load|balancing|goal'
column aq_ha_notifications format a16  heading 'advanced|queueing|high-|availability|notification'

select 
     name
    ,to_char(creation_date, 'mm-dd-yyyy hh24:mi:ss') created_on
    ,goal
    ,clb_goal
    ,aq_ha_notifications
  from dba_services
 where goal is not null
   and name not like 'SYS%'
 order by name
/


ttitle 'current service-level metrics|(from gv$servicemetric)'


--break on service_name noduplicates

column service_name    format a15          heading 'service|name' wrap
column inst_id         format 9999         heading 'inst|id'
column beg_hist        format a10          heading 'start time' wrap
column end_hist        format a10          heading 'end time' wrap
column intsize_csec    format 9999         heading 'intvl|size|(cs)'
column goodness        format 999999       heading 'goodness'
column delta           format 999999       heading 'pred-|icted|good-|ness|incr'
column cpupercall      format 99999999     heading 'cpu|time|per|call|(mus)'
column dbtimepercall   format 99999999     heading 'elpsd|time|per|call|(mus)'
column callspersec     format 99999999     heading '# 0f|user|calls|per|second'
column dbtimepersec    format 99999999     heading 'dbtime|per|second'
column flags           format 999999       heading 'flags'

select
      sm.inst_id    
    , sm.service_name
    , to_char(sm.begin_time,'hh24:mi:ss') beg_hist
    , to_char(sm.end_time,'hh24:mi:ss') end_hist
    , sm.goodness
    , sm.flags
    , ds.goal
    , sm.delta
    , sm.dbtimepercall
    , sm.callspersec
    , sm.dbtimepersec
  from gv$servicemetric sm
     , dba_services ds
 where sm.service_name=ds.name
   and ds.goal is not null
 order by sm.service_name,sm.inst_id,sm.begin_time
/

prompt...
prompt... goodness => indicates how attractive a given instance is with respect to processing the workload that is presented to the service. 
prompt... a lower number is better. this number is internally computed based on the goal (long or short) that is specified for the particular service.
prompt...
prompt... predicted goodness incr => the predicted increase in the goodness for every additional session that is routed to this instance
prompt...
prompt... flags 
prompt...      0x01 - service is blocked from accepting new connections
prompt...      0x02 - service is violating the set threshold on some metric
prompt..       0x04 - goodness is unknown

clear breaks


ttitle 'current connection distribution over the services'

select  
       count(*)
     , inst_id
     , service_name 
	 , username
 from gv$session 
where service_name not like 'SYS%'  
group by service_name,inst_id,username
order by 4
/

ttitle 'current connection over the services for each server'

select  
       count(*)
     , inst_id
     , service_name 
	 , username
	 , machine
 from gv$session 
where service_name not like 'SYS%'  
group by service_name,inst_id,username,machine
order by 5
/

ttitle 'current services defiend but not active? delete script'

column cmd format a100

select 'execute dbms_service.delete_service('''||name||''');' as cmd
  from dba_services 
 where name not in (select name from gv$active_services)
/ 

 

ttitle off
