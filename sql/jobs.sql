--==============================================================================
--
--==============================================================================
SET linesize 130 pagesize 300 recsep off

@jobs_dbms.sql

@jobs_sheduler.sql

prompt
prompt init.ora Settings for the job queue

show parameter job_queue_processes

prompt
prompt
prompt
