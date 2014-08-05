
define SQL_ID='&1'

prompt
prompt Parameter 1 = SQL ID     => &&SQL_ID.
prompt

set pagesize 100
set linesize 130


select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||',@'||inst_id||''';'   
  from gv$session 
 where SQL_ID in ('&&SQL_ID.')
  and status ='ACTIVE'
/ 

