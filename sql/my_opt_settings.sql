--==============================================================================
--
-- Desc:   show the my optimizer settings
--
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF


column name        format a40 heading  "OptFeature|Name" 
column SQL_FEATURE format a20 heading  "SQL|Feature"
column ISDEFAULT   format a4  heading  "DEF|AULT"
column VALUE       format a20 heading  "Value"
column SID         format 9999 heading "My|SID"

select  o.NAME
		, o.SQL_FEATURE
		, o.ISDEFAULT
		, o.VALUE
 from gv$ses_optimizer_env o
    , gv$session s
where s.sid = o.sid
  and s.inst_id=o.inst_id
  and s.username= user
  and s.sid=sys_context('userenv','SID')
order by o.name
/

