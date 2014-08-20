set serveroutput on size 1000000

prompt

DOC
-------------------------------------------------------------------------------
    
    Remove Error Log for SQL Errors over the complete DB
    
-------------------------------------------------------------------------------
#

prompt
set echo on
set serveroutput on

prompt "Info -- delete trigger"
drop TRIGGER log_error;


prompt "Info -- delete Delete Job"
declare
 
 v_job_id dba_jobs.job%type;
 v_count pls_integer:=0;
 
 cursor c_del_job 
 is
 select job,what from dba_jobs where upper(WHAT) like upper('%system.deleteOraErrorTrigTab%');
 
begin 
 dbms_output.put_line('Info -- start remove the error table delete job');
 for rec in c_del_job
 loop
  dbms_output.put_line('Info -- remove JOB ::'||rec.what|| ' with the id::'||to_char(rec.job));
  dbms_job.remove(rec.job);
  commit;
  v_count:=v_count+1;
 end loop;
 dbms_output.put_line('Info -- remove '||to_char(v_count)||' Jobs -- finish');  
end;
/

prompt "Info -- delete Error Table"
drop table  SYSTEM.ora_errors purge;

prompt "Info -- delete Error Sequence"
drop SEQUENCE SYSTEM.ora_errors_seq;

prompt "Info -- delete Error Sequence"
drop  PROCEDURE system.deleteOraErrorTrigTab;



 