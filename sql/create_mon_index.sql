-- =================================================
-- create the scripts to enable and disable  
--
-- =================================================

set verify  off
set linesize 130 pagesize 4000 recsep off

define OWNER    = '&1' 

prompt
prompt Parameter 1 = Owner Name => &&OWNER.
prompt
 
variable own varchar2(20);
exec :own := upper('&&OWNER');

set heading off
 
col SPOOL_NAME_COL new_val SPOOL_NAME
 
SELECT replace(ora_database_name||'_'||SYS_CONTEXT('USERENV','HOST')||'_'||to_char(sysdate,'dd_mm_yyyy_hh24_mi')||'_enable_monitoring','\','_') 
--' resolve syntax highlight bug FROM my editer .-(
  AS SPOOL_NAME_COL
FROM dual
/


-----------------------------------------------------------------
-- on
-----------------------------------------------------------------

spool &&SPOOL_NAME._on.sql

prompt 
prompt spool recreate_&&SPOOL_NAME._on.log
prompt

prompt prompt  ============ Start ================
prompt select to_char(sysdate,'dd.mm.yyyy hh24:mi') as start_date from dual
prompt /
prompt prompt  ===================================
prompt 
prompt  

prompt set heading   on
prompt set echo      on
prompt set feedback  on
prompt set define   off
prompt ALTER SESSION SET ddl_lock_timeout=5;

select 'alter index '||owner||'.'||index_name||' monitoring usage;'
 from all_indexes
where owner=:own
  and table_owner=:own
  and table_name in (
  'S_ACT_CONTACT'
,'S_ACT_EMP'
,'S_ADDR_PER'
,'S_CON_CHRCTR'
,'S_CONTACT'
,'S_CONTACT_BU'
,'S_CONTACT_X'
,'S_CONTACT_XM'
,'S_EVT_ACT'
,'S_EVT_ACT_X'
,'S_EVT_CAL'
,'S_EVT_MKTG'
,'S_PARTY'
,'S_POSTN_CON'
,'S_SRV_ACT'
,'S_SRV_REQ'
,'S_SRV_REQ_BU'
)  
order by table_name, index_name
/

prompt 
prompt prompt  ============ Finish ================
prompt select to_char(sysdate,'dd.mm.yyyy hh24:mi') as finish_date from dual
prompt /
prompt prompt  ===================================
prompt 
prompt prompt to check the log see recreate_&&SPOOL_NAME._on.log

prompt set heading  on
prompt set feedback off
prompt set define on
prompt spool off
 
spool off;

-----------------------------------------------------------------
-- off
-----------------------------------------------------------------

spool &&SPOOL_NAME._off.sql

prompt 
prompt spool recreate_&&SPOOL_NAME._off.log
prompt
prompt prompt  ============ Start ================
prompt select to_char(sysdate,'dd.mm.yyyy hh24:mi') as start_date from dual
prompt /
prompt prompt  ===================================
prompt 
prompt  

prompt set heading   on
prompt set echo      on
prompt set feedback  on
prompt set define   off
prompt ALTER SESSION SET ddl_lock_timeout=5;

select 'alter index '||owner||'.'||index_name||' nomonitoring usage;'
 from all_indexes
where owner=:own
  and table_owner=:own
  and table_name in (
  'S_ACT_CONTACT'
,'S_ACT_EMP'
,'S_ADDR_PER'
,'S_CON_CHRCTR'
,'S_CONTACT'
,'S_CONTACT_BU'
,'S_CONTACT_X'
,'S_CONTACT_XM'
,'S_EVT_ACT'
,'S_EVT_ACT_X'
,'S_EVT_CAL'
,'S_EVT_MKTG'
,'S_PARTY'
,'S_POSTN_CON'
,'S_SRV_ACT'
,'S_SRV_REQ'
,'S_SRV_REQ_BU'
)  
order by table_name, index_name
/

prompt 
prompt prompt  ============ Finish ================
prompt select to_char(sysdate,'dd.mm.yyyy hh24:mi') as finish_date from dual
prompt /
prompt prompt  ===================================
prompt 
prompt prompt to check the log see recreate_&&SPOOL_NAME._off.log

prompt set heading  on
prompt set feedback off
prompt set define on
prompt spool off
 
spool off

-----------------------------------------------------------------

prompt .........
prompt to enable index monitoring for all indexes of this user use:
prompt &&SPOOL_NAME._on.sql
prompt 

prompt .........
prompt to disable index monitoring for all indexes of this user use:
prompt &&SPOOL_NAME._off.sql
prompt 
 
set heading on 
