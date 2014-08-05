--==============================================================================
-- Show all external tables in the database
-- Must be run with dba privileges 
--==============================================================================

set verify  off
set linesize 120 pagesize 4000 recsep OFF

column  OWNER           format a20    heading "Owner"
column  TABLE_NAME      format a20    heading "Table|Name"
column  LOCATION        format a30    heading "Location"
column  DIRECTORY_OWNER format a3     heading "DO"
column  DIRECTORY_NAME  format a20    heading "Directory|Name"

select OWNER
		, TABLE_NAME
		, LOCATION
		, DIRECTORY_OWNER
		, DIRECTORY_NAME
 from DBA_EXTERNAL_LOCATIONS
order by OWNER
        ,TABLE_NAME
/		  

prompt 
prompt Details ...
prompt 

column  REJECT_LIMIT      format a20  heading "Reject|Limit"
column  ACCESS_TYPE       format a20  heading "Access|Type"
column  PROPERTY          format a10  heading "Property"
column  ACCESS_PARAMETERS format a80  heading "Access|Parameter" Fold_before WORD_WRAPPED

select  TABLE_NAME
      , REJECT_LIMIT
      , ACCESS_TYPE
		, PROPERTY 
		, ACCESS_PARAMETERS
from DBA_EXTERNAL_TABLES
order by OWNER
        ,TABLE_NAME
/

