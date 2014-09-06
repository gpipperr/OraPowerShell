--==============================================================================
-- get all possible properties of a target Type
--==============================================================================

SET linesize 240 pagesize 400 recsep OFF


define TARGET_TYPE  = '&1' 

prompt
prompt get properites of the target types in the OEM Repostiory with a target
prompt Parameter 1 =  Target Type => &&TARGET_TYPE.
prompt 

column target_type   format a40 heading "Target Types"
column property_name format a40 heading "Property | Name"

select property_name
     , target_type 
  from mgmt$target_properties 
 where lower(target_type) like lower('&&TARGET_TYPE')
group by property_name
       , target_type
order by property_name
/
