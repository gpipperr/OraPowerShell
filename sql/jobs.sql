--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   show all jobs in the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
-- some usefull hints
-- https://community.oracle.com/thread/648581
--===============================================================================

SET linesize 150 pagesize 400 recsep OFF

ttitle left  "Job Infos -- Oracle JOB Table " skip 2

column job          format 9999999
column what         format a15
column last_date    format a13
column this_date    format a13
column next_date    format a13
column interval     format a20
column broken       format a2
column schema_user  format a10

column owner        format a10

select job
      ,schema_user
      ,substr(what, 1, 20) as what
      ,to_char(last_date, 'dd.mm hh24:mi') as last_date
      ,to_char(this_date, 'dd.mm hh24:mi') as this_date
	  ,to_char(next_date, 'dd.mm hh24:mi') as next_date
      ,interval
		,failures
      ,broken
  from dba_jobs
/

column what format a100

select job
      ,WHAT as what      
  from dba_jobs
/

ttitle left  "Job Infos -- Oracle JOB Table Jobs with failures " skip 2

select job
      ,schema_user
      ,substr(what, 1, 20) as what
      ,to_char(last_date, 'dd.mm hh24:mi') as last_date
      ,to_char(this_date, 'dd.mm hh24:mi') as this_date
	  ,to_char(next_date, 'dd.mm hh24:mi') as next_date
      ,interval
		,failures
      ,broken
  from dba_jobs
where failures > 0
/


ttitle "Job Scheduler Information -- Oracle scheduler table " skip 2

column log_id       format 9999999   heading "Log|id"
column log_date     format a13      heading "Log|date"
column job_name     format a30      heading "Job|name"
column status       format a10      heading "Job|status"
column cpu_used     format a10      heading "Cpu|used"
column program_name format a20      heading "Program|name"
column last_start_date format a18   heading "Last|start date"
column failure_count format 999     heading "Fail|cnt"
column next_run_date  like  last_start_date heading "Last|start date"

select owner
      ,job_name
		,state
	  ,program_name
      ,run_count
      ,failure_count
      ,to_char(last_start_date, 'dd.mm hh24:mi') as last_start_date
      ,to_char(next_run_date, 'dd.mm hh24:mi')   as next_run_date
  from dba_scheduler_jobs
 order by owner
/   

ttitle  "Job Scheduler History -- Oracle scheduler table of the last day - only the last 20" skip 2

select * from (
	select log_id
		  ,to_char(log_date, 'dd.mm hh24:mi') as log_date
		  ,owner
		  ,job_name
		  ,status
	  from dba_scheduler_job_log
	 where log_date > (sysdate - 1)
	 order by log_date
			 ,owner
)
where rownum < 20	 
/

ttitle  "Job Scheduler History -- Summary" skip 2

select    owner
		  , job_name
		  , nvl(status,'-') as status
		  , count(*)		  
	  from dba_scheduler_job_log
	 where log_date > (sysdate - 1)
	 group by  owner
		  , job_name
		  , nvl(status,'-')
order by owner
       , job_name
/			 
			 			 

TTITLE 'Scheduled Tasks duration histroy of the last day - only the first 40'

select * from (
	select l.job_name
		  ,sum(extract(second from d.cpu_used) + (extract(minute from d.cpu_used) * 60) +
			   (extract(hour from d.cpu_used) * 60 * 60)) as timeused
		  ,l.log_id
	  from dba_scheduler_job_log         l
		  ,dba_scheduler_job_run_details d
	 where d.log_id = l.log_id
	   and d.log_date > (sysdate - 1)
	 group by l.job_name
			 ,l.log_id
	 order by l.log_id
)
where rownum < 40	 
/

-- What scheduled tasks failed during execution, and why?

TTITLE 'Scheduled Tasks That Failed'
prompt  Scheduled Tasks That Failed:

column log_date            format a32    heading 'Log Date'
column owner               format a06    heading 'Owner'
column job_name            format a26    heading 'Job'
column status              format a10    heading 'Status'
column actual_start_date   format a32    heading 'Actual|Start|Date'
column error#              format 999999 heading 'Error|Nbr'

select log_id
      ,log_date
      ,owner
      ,job_name
      ,status
      ,substr(actual_start_date,1,18)||' ...' as actual_start_date
      ,error#
  from dba_scheduler_job_run_details
 where nvl(status,'-') <> 'SUCCEEDED'
	and  log_date > (sysdate - 1) 
 order by log_id desc
/ 

TTITLE 'Scheduled Tasks without a Status - may be failed'
prompt  Scheduled Tasks That Failed:

select log_id
      ,log_date
      ,owner
      ,job_name
      ,status
      ,OPERATION
  from  dba_scheduler_job_log	
 where nvl(status,'-') <> 'SUCCEEDED'
 	and  log_date > (sysdate - 1) 
 order by log_id desc
/ 



TTITLE 'Auto Tasks:'
prompt  Auto Task  overview:

column client_name       format a35 heading "Job|Name"
column status            format a10 heading "Job|status"
column mean_job_duration format a10 heading "Mean|duration"
column mdl7              format a10 heading "Max|duration"
column next_start_date   format a18 heading "Next|run"
column window_group_name format a18 heading "Window|group"

select c.client_name
     , c.status
	 , w.window_group_name
	 , w.next_start_date
	 , c.mean_job_duration
	 , c.max_duration_last_7_days as mdl7
from  dba_autotask_client c
    , dba_scheduler_window_groups w
where w.window_group_name=c.window_group
order by 1
/

ttitle off
prompt
prompt init.ora Settings for the job queue

show parameter job_queue_processes

prompt
prompt
prompt
