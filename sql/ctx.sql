--==============================================================================
-- Author: Gunther Pipp�rr ( http://www.pipperr.de )
-- ctx.sql
-- get the oracle text parameters of one schema user
-- Parameter 1: Name of the User 
--
-- Must be run with dba privileges
-- 
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify  off
set linesize 120 pagesize 4000 recsep OFF

define USER_NAME = &1 

-- may be later helpfull for indexed tables?
--select * 
--  from dba_lobs 
--where upper(owner) in (upper('&&USER_NAME.'))
--/ 

ttitle left  "Oracle Text Indexes for the user &&USER_NAME." skip 2

column idx_owner  format a15 heading "Qwner" 
column table_name format a35 heading "Table/View Name"
column idx_name   format a25 heading "Name" 
column idx_status format a8 heading  "Status" 
column idx_type   format a12 heading "Index Type" 

select idx_owner
      ,idx_name
	  ,idx_table_owner||'.'||idx_table as table_name
	  ,idx_status
	  ,idx_type
 from ctxsys.ctx_indexes 
 where upper(idx_owner) in (upper('&&USER_NAME.'))
/ 

--
-- create the CTX_REPORT.DESCRIBE_INDEX sql's
--

set long 64000
set pages 0
set heading off
set feedback off
spool get_ctx_desc_report.sql
select 'select ctx_report.describe_index('''||idx_owner||'.'||idx_name||''') from dual;'
  from ctxsys.ctx_indexes 
 where upper(idx_owner) in (upper('&&USER_NAME.'))
/
spool off

spool get_ctx_stat_report.sql
select 'select ctx_report.INDEX_STATS('''||idx_owner||'.'||idx_name||''') from dual;'
  from ctxsys.ctx_indexes 
 where upper(idx_owner) in (upper('&&USER_NAME.'))
/
spool off
set pages 100
set heading on
set feedback on

prompt ... to get the full informations over the indexes call the generated
prompt ... sql report @get_ctx_desc_report.sql 
prompt
prompt ... to get the statistic informations over the indexes call the generated 
prompt ... sql report @get_ctx_stat_report.sql 
prompt
 
ttitle left  "Oracle Text Parameters" skip 2

column par_name  format a25 heading "Parameter" 
column par_value format a30 heading "Value" 

select par_name
     , par_value
 from ctxsys.ctx_parameters
order by 1 
/ 

ttitle left  "Oracle Text Preferences" skip 2


column pre_owner  format a15 heading "Owner" 
column pre_name   format a35 heading "Parameter" 
column pre_class  format a15 heading "Class" 
column pre_object format a35 heading "Object" 

select 	 pre_owner
	   , pre_name
       , pre_class
       , pre_object
  from ctxsys.ctx_preferences 
 where upper(pre_owner) in (upper('&&USER_NAME.'))
order by 1,2,3
/

ttitle left  "Oracle Text Attributes" skip 2

column prv_owner      format a15 heading "Owner" 
column prv_preference format a30 heading "Perference" 
column  prv_attribute format a20 heading "Attribute" 
column prv_value      format a50 heading "Value" 

select prv_owner
	,  prv_preference
	,  prv_attribute
	,  prv_value 
 from  ctxsys.ctx_preference_values 
 where upper(prv_owner) in (upper('&&USER_NAME.'))
order by 1,2,3,4
/ 

ttitle off

