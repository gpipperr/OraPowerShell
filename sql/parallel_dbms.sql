SET linesize 73 pagesize 400 recsep OFF
ttitle left  "DBMS_PARALLEL chunks in Work" skip 2

column "Chunks" format a20
column Status format a20

SELECT to_char(count(*)) as "Chunks" ,status
FROM   dba_parallel_execute_chunks
group by status
/

ttitle left  "DBMS_PARALLEL Errors" skip 2

column error_message format a100

select task_name
      ,status
			,error_code
			,error_message 
 from dba_parallel_execute_chunks 
where error_message is not null
/


ttitle off