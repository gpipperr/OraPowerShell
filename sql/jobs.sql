--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the user rights and grants
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 120 pagesize 400 recsep OFF

ttitle left  "Job Infos -- Oracle JOB Table " skip 2

column what        format a20
column last_date   format a13
column this_date   format a13
column interval    format a20
column broken      format a2
column SCHEMA_USER format a10

select job
      ,SCHEMA_USER
      ,substr(WHAT, 1, 20) as what
      ,to_char(LAST_DATE, 'DD.MM HH24:MI') as last_date
      ,to_char(THIS_DATE, 'DD.MM HH24:MI') as this_date
      ,interval
      ,broken
  from all_jobs
/

ttitle left  "Job Scheduler Information -- Oracle scheduler table " skip 2

select OWNER
      ,JOB_NAME
      ,RUN_COUNT
      ,FAILURE_COUNT
      ,to_char(LAST_START_DATE, 'DD.MM HH24:MI') as LAST_START_DATE
      ,to_char(NEXT_RUN_DATE, 'DD.MM HH24:MI') as NEXT_RUN_DATE
  from dba_scheduler_jobs
 order by owner
/   

ttitle left  "Job Scheduler History -- Oracle scheduler table of the last hour" skip 2

column log_id     FORMAT 999999   HEADING 'Log#'
column log_date   FORMAT A13      HEADING 'Log Date'
column owner      FORMAT A08      HEADING 'Owner'
column job_name   FORMAT A25      HEADING 'Job'
column status     FORMAT A10      HEADING 'Status'
column cpu_used   FORMAT A10

select log_id
      ,to_char(log_date, 'DD.MM HH24:MI') as log_date
      ,owner
      ,job_name
      ,status
  from dba_scheduler_job_log
 where log_date > sysdate - (1 / 24)
 order by log_date
         ,owner
/

TTITLE 'Scheduled Tasks duration histroy of the last hour'

select l.job_name
      ,sum(extract(second from d.cpu_used) + (extract(MINUTE from d.cpu_used) * 60) +
           (extract(HOUR from d.cpu_used) * 60 * 60)) as timeused
      ,l.log_id
  from dba_scheduler_job_log         l
      ,dba_scheduler_job_run_details d
 where d.log_id = l.log_id
   and d.log_date > sysdate - (1 / 24)
 group by l.job_name
         ,l.log_id
 order by l.log_id
/

-- What scheduled tasks failed during execution, and why?
COL log_id              FORMAT 9999   HEADING 'Log#'
COL log_date            FORMAT A32    HEADING 'Log Date'
COL owner               FORMAT A06    HEADING 'Owner'
COL job_name            FORMAT A20    HEADING 'Job'
COL status              FORMAT A10    HEADING 'Status'
COL actual_start_date   FORMAT A32    HEADING 'Actual|Start|Date'
COL error#              FORMAT 999999 HEADING 'Error|Nbr'

TTITLE 'Scheduled Tasks That Failed:'
select log_id
      ,log_date
      ,owner
      ,job_name
      ,status
      ,actual_start_date
      ,error#
  from dba_scheduler_job_run_details
 where status <> 'SUCCEEDED'
 order by actual_start_date
/ 

ttitle off
