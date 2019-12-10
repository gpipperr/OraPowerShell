define SYSUSER_PWD='&1'
define AUDITLOG_TAB_LOC='&2'

connect "SYS"/"&&SYSUSER_PWD" as SYSDBA
set echo on
spool $SCRIPTS/gpi_setup.log append

--- Move Audit log tablespace

CREATE SMALLFILE TABLESPACE "AUDITLOG"  LOGGING DATAFILE '&&AUDITLOG_TAB_LOC' 
	   SIZE 100M AUTOEXTEND ON NEXT 120M MAXSIZE 32000M EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT  AUTO
/		 

BEGIN
DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
       audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_DB_STD,
       audit_trail_location_value =>  'AUDITLOG');
END;
/

--- recompile invalid objects --------------

@?/rdbms/admin/utlrp.sql

-- Auditlog init ---------------------------

-- see https://www.pipperr.de/dokuwiki/doku.php?id=dba:oracle_clean_audit_log_entries

BEGIN
  DBMS_AUDIT_MGMT.INIT_CLEANUP(
      audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL,
      default_cleanup_interval => 24 /* hours */);
END;
/

--  Delete all after 180 Days

BEGIN
-- Standard database audit records in the SYS.AUD$ table
  DBMS_AUDIT_MGMT.set_last_archive_timestamp(
       audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD
     , last_archive_time => SYSTIMESTAMP-180);
 
--  Unified audit trail. In unified auditing, all audit records are written to the unified audit trail and are made --  available through the unified audit trail views, such as UNIFIED_AUDIT_TRAIL.
 DBMS_AUDIT_MGMT.set_last_archive_timestamp(
       audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED
     , last_archive_time => SYSTIMESTAMP-180);
 
-- Operating system audit trail. This refers to the audit records stored in operating system files.
  DBMS_AUDIT_MGMT.set_last_archive_timestamp(
       audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_OS
     , last_archive_time => SYSTIMESTAMP-180);
 
END;
/

-- create the job to move the timeframe each day
BEGIN
 
  DBMS_SCHEDULER.CREATE_JOB (
    job_name   => 'AUDIT_ARCHIVE_BEFORE_TIMESTAMP',
    job_type   => 'PLSQL_BLOCK',
    job_action => 'begin 
  DBMS_AUDIT_MGMT.set_last_archive_timestamp(
       audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD
     , last_archive_time => SYSTIMESTAMP-180);
  DBMS_AUDIT_MGMT.set_last_archive_timestamp(
       audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED
     , last_archive_time => SYSTIMESTAMP-180);
  DBMS_AUDIT_MGMT.set_last_archive_timestamp(
       audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_OS
     , last_archive_time => SYSTIMESTAMP-180);
   end;',
     start_date      => sysdate,
     repeat_interval => 'FREQ=HOURLY;INTERVAL=24',
     enabled         =>  TRUE,
     comments        => 'Set the point in time before delete all audit log entries'
  );
END;
/


-- Create Auditlog purge Job ------------------
BEGIN
  DBMS_AUDIT_MGMT.create_purge_job(
    audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL,
    audit_trail_purge_interval => 24 /* hours */,  
    audit_trail_purge_name     => 'PURGE_ALL_AUDIT_TRAILS',
    use_last_arch_timestamp    => TRUE);
END;
/

--- Default Auditlog Settings -----------------

-- 
audit connect;
audit create session by access;
audit create session whenever not successful;

---
audit alter any table by access;
audit create any table by access;
audit drop any table by access;
audit create any procedure by access;
audit drop any procedure by access;
audit alter any procedure by access;
audit grant any privilege by access;
audit grant any object privilege by access;
audit grant any role by access;
audit audit system by access;
audit create external job by access;
audit create any job by access;
audit create any library by access;
audit create public database link by access;
audit exempt access policy by access;
audit alter user by access;
audit create user by access;
audit role by access;
audit drop user by access;
audit alter database by access;
audit alter system by access;
audit alter profile by access;
audit drop profile by access;
audit database link by access;
audit system audit by access;
audit profile by access;
audit public synonym by access;
audit system grant by access;

 
-- Audit failed commands and connects
-- will audit all the commands listed for alter system, cluster, database link, procedure, rollback segment, sequence, synonym, table, tablespace, type, and view
audit resource whenever not successful;

--
audit insert, update, delete on sys.aud$ by access;


-- generate a fresh db statistic ---------------

exec DBMS_STATS.gather_system_stats();


----- Disable the auto tuning task ------------
BEGIN
  DBMS_AUTO_TASK_ADMIN.disable(
    client_name => 'sql tuning advisor',
    operation   => NULL, 
    window_name => NULL);
END;
/
commit;
------

--- set the default profile

Alter profile default limit PASSWORD_LIFE_TIME UNLIMITED;

------- finish default GPI settings -------

-------- Init ORA Adjustments

-- DDL Behavior create varchar2 and Blob Columns
alter system set nls_length_semantics='CHAR' scope=both sid='*';
alter system set db_securefile='PREFERRED'   scope=both sid='*';

-- Jobs
alter system set job_queue_processes=25      scope=both sid='*'; 

--- Tuning
alter system set query_rewrite_enabled='True'       scope=both sid='*';
alter system set query_rewrite_integrity='ENFORCED' scope=both sid='*';

-------------

---------------------------------------------------------------
-- Service names

--
-- set the environment in which you run the scripts before you start them!
--

declare
   TYPE serv_tab IS TABLE OF varchar2(200) INDEX BY BINARY_INTEGER;
   v_service serv_tab;
   cursor v_check_service(p_name varchar2) is select count(*) as serv_count from dba_services where upper(name)=upper(p_name);   
   v_count pls_integer;
   v_env varchar2(10):='SRV';
   v_srv_list varchar2(4000);
   v_db_name varchar2(64);
begin

    select global_name into v_db_name from global_name;
   
    v_env:=v_env||'_'||v_db_name;

    v_service(1):=v_env||'_MAIN';
	v_service(2):=v_env||'_USER';
	v_service(3):=v_env||'_REPORT';
	v_service(4):=v_env||'_ADMIN';
	v_service(5):=v_env||'_IMPORT';

	for i in v_service.first .. v_service.last
	loop
		if v_service.exists(i) then
			-- check if the service exists
			v_count:=0;
			open v_check_service(p_name => v_service(i) );
			 fetch v_check_service into v_count;
			close v_check_service;
			begin
				if v_count < 1 then
					dbms_output.put_line('-- Info :: create and start Service ::'||v_service(i));	
					dbms_service.CREATE_SERVICE(SERVICE_NAME=>v_service(i)       
											  , NETWORK_NAME=>v_service(i));
					dbms_service.START_SERVICE(v_service(i));
				else
				  dbms_output.put_line('-- Info :: Service exists ::'||v_service(i));			   
				end if;	
			exception 
			  when others then
			  dbms_output.put_line('-- Info :: Error create Service ::'||v_service(i)||' Error::'||SQLERRM);			   
			end;
			if i = 1
             then
                v_srv_list := '''' || v_service (i);
			else
				v_srv_list := v_srv_list || ''',''' || v_service (i);
			end if;
			
		end if;
	end loop;
    
	dbms_output.put_line('-- Info :: Set Service List with => ::'||'alter system set service_names='||v_srv_list||''' scope=both sid=''*''' );	
	
    execute immediate 'alter system set service_names='||v_srv_list||''' scope=both sid=''*''';	
	
end;
/

show parameter service


spool off

exit;
