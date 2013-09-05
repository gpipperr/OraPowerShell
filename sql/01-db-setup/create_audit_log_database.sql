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
BEGIN
  DBMS_AUDIT_MGMT.INIT_CLEANUP(
      audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL,
      default_cleanup_interval => 24 /* hours */);
END;
/
-- Create Auditlog purge Job ------------------
BEGIN
  DBMS_AUDIT_MGMT.create_purge_job(
    audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_ALL,
    audit_trail_purge_interval => 720 /* hours */,  
    audit_trail_purge_name     => 'PURGE_ALL_AUDIT_TRAILS',
    use_last_arch_timestamp    => TRUE);
END;
/