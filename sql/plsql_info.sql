-- http://docs.oracle.com/cd/B28359_01/server.111/b28320/statviews_2009.htm#REFRN20385
-- http://docs.oracle.com/cd/B28359_01/server.111/b28320/statviews_2013.htm#REFRN20168
-- http://www.oracle.com/technetwork/issue-archive/2012/12-nov/o62plsql-1851968.html
-- http://docs.oracle.com/cd/E16655_01/network.121/e17607/dr_ir.htm#DBSEG658

set verify  off
set linesize 120 pagesize 4000 recsep OFF

define OBJ_NAME = '&1' 

prompt
prompt Parameter 1 = PLSQL NAME         => &&OBJ_NAME.
prompt

column OWNER                format A15
column NAME                 format A15
column TYPE                 format A12
column PLSQL_OPTIMIZE_LEVEL format 99 heading "OL"
column PLSQL_CODE_TYPE      format A12 heading "Code|Type" 
column PLSQL_DEBUG			 format A8 heading "Debug"
column PLSQL_WARNINGS       format A15 heading "Warn"
column NLS_LENGTH_SEMANTICS format A15 
column PLSQL_CCFLAGS        format A10 heading "CC Flag" 
column PLSCOPE_SETTINGS     format A18


select 
	  OWNER               
	, NAME                
	, TYPE                
	, PLSQL_OPTIMIZE_LEVEL
	, PLSQL_CODE_TYPE     
	, PLSQL_DEBUG			
	, PLSQL_WARNINGS      
	--, NLS_LENGTH_SEMANTICS
	, PLSQL_CCFLAGS       
	, PLSCOPE_SETTINGS    
 from DBA_PLSQL_OBJECT_SETTINGS 
where NAME like upper('&&OBJ_NAME.');

column OBJECT_NAME    format A20
column PROCEDURE_NAME format A20
column OVERLOAD 		 format A20
column OBJECT_TYPE 	 format A20
column IMPLTYPEOWNER  format A20
column IMPLTYPENAME 	 format A20
column AUTHID 			 format A20

select owner 
	,  OBJECT_NAME
	,	PROCEDURE_NAME
	--, OVERLOAD
	, OBJECT_TYPE
	 --AGGREGATE
	 --PIPELINED
	--, IMPLTYPEOWNER
	--, IMPLTYPENAME
	--PARALLEL
	--,INTERFACE
	, DETERMINISTIC
	, AUTHID
 from dba_procedures  
where object_name like upper('&&OBJ_NAME.')
/

prompt ... AUTHID - Indicates whether the procedure/function is declared to execute as DEFINER or CURRENT_USER (invoker)


select owner
  --  ,  SUBOBJECT_NAME
    ,  OBJECT_TYPE
    , to_char(CREATED,'dd.mm.yyyy hh24:mi') as CREATED
	,  to_char(LAST_DDL_TIME,'dd.mm.yyyy hh24:mi') as LAST_DDL_TIME
	,  TIMESTAMP
	,  STATUS
from dba_objects
where OBJECT_NAME like  upper('&&OBJ_NAME.')
/
