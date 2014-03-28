--
-- http://docs.oracle.com/cd/E11882_01/server.112/e17120/dbrm.htm#ADMIN027
--

SET linesize 130 pagesize 100 recsep OFF

prompt .... Viewing Consumer Groups Granted to Users or Roles

select grantee
	,   granted_group
	,   grant_option
	,   initial_group
 from dba_rsrc_consumer_group_privs
order by  grantee
/

prompt .. Viewing Plan Schema Information

column plan          format a27 heading "Plan"
column status        format a10 heading "Status"
column comments      format a100 heading "Comment" WORD_WRAPPED 
column cpu_method    format a10 heading "CPU_METHOD"
column mgmt_method   format a10 heading "CPU_METHOD"
column parallel      format a20 fold_after 
 
select plan
     , status 
	  , cpu_method
	  , mgmt_method
	  , parallel_degree_limit_mth as parallel
	  , comments	  
 from dba_rsrc_plans 
order by status 
/

prompt .. show user waiting with resource limit

select sid
     , serial#
     , username
	  , resource_consumer_group 
 from v$session
where event like 'resmgr%'
/


--http://docs.oracle.com/cd/B28359_01/server.111/b28310/dbrm009.htm#ADMIN11906




