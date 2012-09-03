CREATE USER backupuser IDENTIFIED BY system DEFAULT TABLESPACE users TEMPORARY TABLESPACE TEMP;
GRANT CONNECT, RESOURCE, RECOVERY_CATALOG_OWNER TO backupuser;
grant select on v_$instance TO backupuser;
grant select on v_$version TO backupuser;
grant select on DBA_DIRECTORIES to backupuser;
grant create any DIRECTORY to backupuser;
grant EXP_FULL_DATABASE  to backupuser;
grant ALTER DATABASE to backupuser;


-- FIX 
--SQLPLUS OUT:: CREATE pfile='d:\oracle\flash_recovery_area\g
--SQLPLUS OUT:: *
--SQLPLUS OUT:: FEHLER in Zeile 1:
--SQLPLUS OUT:: ORA-01031: Nicht ausreichende Berechtigungen

grant sysdba to backupuser;

---

grant select on sys.registry$history to backupuser

---


