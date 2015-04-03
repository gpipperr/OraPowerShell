--==============================================================================
--
--==============================================================================
set verify off
set linesize 130 pagesize 300 recsep off

define SQL_ID='&1'

prompt
prompt Parameter 1 = SQL ID     => &&SQL_ID.
prompt



select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||',@'||inst_id||''';'   
  from gv$session 
 where SQL_ID in ('&&SQL_ID.')
  and status ='ACTIVE'
/ 

select 'ALTER SYSTEM DISCONNECT SESSION '''||sid||','||serial#||''' IMMEDIATE;' 
  from v$session 
 where sql_id='&&SQL_ID.'
/

