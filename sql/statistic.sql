--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   Main statistic information of the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 120

ttitle left  "Workload Statistik Values" skip 2

column SNAME format a15 heading "Statistic|Name"
column pname format a12 heading "Parameter"
column PVAL1 format 99999D99 heading "Value 1"
column PVAL2 format a20 heading "Value 2"

select sname
	, pname
	, pval1
	, pval2 
from sys.aux_stats$
order by 1,2
/

ttitle left  "LAST ANALYZED Tables Overview" skip 2

column last_an   format a18  heading "Last|analyzed"
column owner     format a15  heading "Tab|Owner"
column tab_count format 9999 heading "Tab|Count"

select  last_an
      , owner
	  , tab_count 
 from (
	select   to_char(last_analyzed,'dd.mm.yyyy hh24:mi') as last_an
		   , owner
		   , count(*)  as tab_count
		   , to_char(last_analyzed,'yyyymmddhh24mi') as sort	
	  from dba_tables 
	 group by owner,to_char(last_analyzed,'dd.mm.yyyy hh24:mi') ,to_char(last_analyzed,'yyyymmddhh24mi')
    )
order by sort asc ,owner desc
/

prompt...
prompt... if last analyzed is empty there are some tables witout statistics in this schema
prompt... check especially for none sys user
prompt...

 
ttitle left  "Overview histogramm statistic usage for none system user in the database" skip 2
 
column table_name   format a25 heading "Table Name"
 
select owner
     , count(distinct table_name) as count_tables
     --, column_name 
     , count(*) as count_hist_buckets
 from DBA_TAB_HISTOGRAMS 
where owner not in ('SYS','SYSTEM','SYSMAN','APEX_030200','XDB','ORDDATA','MDSYS','OLAPSYS','CTXSYS','SYSMAN_MDS','EXFSYS','DBSNMP','ORDSYS','WMSYS','APEX_030200','PEFSTAT')
 --and  owner like 'INTERSHOP_LIVE'
group by owner --table_name ,column_name
order by owner
/


ttitle left  "Job Scheduler Information -- Oracle Statistik Auto Job " skip 2

column JOB_NAME        format a30 heading "Job|Name"
column RUN_COUNT       format 99999 heading "Run|Count"
column FAILURE_COUNT   format 99999 heading "Failure|Count"
column LAST_START_DATE format a18 heading "Last|run date"
column NEXT_RUN_DATE   format a18 heading "Next|run date"

select OWNER
      ,JOB_NAME
      ,RUN_COUNT
      ,FAILURE_COUNT
      ,to_char(LAST_START_DATE, 'DD.MM.YYYY HH24:MI') as LAST_START_DATE
      ,to_char(NEXT_RUN_DATE, 'DD.MM.YYYY HH24:MI') as NEXT_RUN_DATE
  from dba_scheduler_jobs
  where job_name like '%STAT%'
 /   
 
prompt ... GATHER_STATS_JOB 10g job should not run in 11g!

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
 
 
