--==============================================================================
-- GPI - Gunther Pippèrr
-- Desc:   Get the audit settings of the database
--
-- Must be run with dba privileges
--
--==============================================================================
set linesize 130 pagesize 300 recsep off

ttitle left  "Audit settings -- init.ora " skip 2

show parameter audit

ttitle left  "Audit Settings -- Parameters " skip 2

column parameter_name  format a30
column parameter_value format a20
column audit_trail     format a20

select  parameter_name
      , parameter_value
	  , audit_trail 
  from dba_audit_mgmt_config_params
order by 1  
/

ttitle left  "Audit Settings -- Audit objects" skip 2

column audit_option format a30
column success format a12
column failure format a12

select  audit_option
      , success,failure 
  from dba_stmt_audit_opts
 order by 1  
/  

--DBA_AUDIT_OBJECT

ttitle off
