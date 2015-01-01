--==============================================================================
-- get all info over the  properties of one target of this type
--==============================================================================

SET linesize 240 pagesize 400 recsep OFF


define TARGET_TYPE  = '&1' 

prompt
prompt get properites of the target types in the OEM Repostiory with a target
prompt Parameter 1 =  Target Type => &&TARGET_TYPE.
prompt 

column property_value   format a40 heading "Property Target"
column property_name format a40 heading "Property  Name"
column target_name format a40 heading "Target  Name"

break on target_name

select target_name 	  	 
     ,  property_name
     , property_value      	   
  from mgmt$target_properties 
 where target_name = ( select target_name from  mgmt$target_properties where lower(target_type) like lower('&&TARGET_TYPE') and rownum =1)  
order by property_name
/

clear break