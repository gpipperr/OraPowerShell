set verify  off
set linesize 120 pagesize 4000 recsep OFF

define OBJ_NAME = '&1' 

prompt
prompt Parameter 1 = OBJ Name          => &&OBJ_NAME.
prompt


column OBJECT_NAME format a30
column OBJECT_TYPE format a16
column LAST_DDL_TIME format a18

select OBJECT_NAME
     , OBJECT_TYPE
	  , to_char(LAST_DDL_TIME ,'dd.mm.yyyy hh24:mi') as LAST_DDL_TIME
from user_objects
where OBJECT_NAME like upper('%&OBJ_NAME.%')
order by OBJECT_NAME,OBJECT_TYPE
/