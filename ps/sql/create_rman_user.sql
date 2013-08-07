--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   create the user to do Oracle Backup wiht an other user then sys
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
prompt "SYS user required!"

--- Create user
create user backupuser identified by system default tablespace users temporary tablespace temp;

--- grant roles  
grant connect, resource, recovery_catalog_owner to backupuser;
grant create any directory to backupuser;
grant exp_full_database to backupuser;
grant alter database to backupuser;
grant sysdba to backupuser;

--- objects
grant select on sys.registry$history to backupuser;
grant select on v_$instance to backupuser;
grant select on v_$version to backupuser;
grant select on dba_directories to backupuser;
grant select on v_$parameter to backupuser;
grant select on v_$diag_info to backupuser;

---


