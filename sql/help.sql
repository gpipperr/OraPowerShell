--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script Overview
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

DOC 
-------------------------------------------------------------------------------
 
#The daily scripts
=================

	- dict.sql             - query the data dictionary - parameter 1 - part of the comments text

	- database.sql         - name and age of the database
	- status.sql           - status of the instance/cluster
	- date.sql             - get the actual date and time of the DB
	- instance.sql         - status of the instance where the user is connected
	- limit.sql            - resource limits since last startup of the instances
	- tablespace.sql       - Information about the tablespaces
	- tablespace_usage.sql - Information usage on a tablespace - Parameter 1 the name of the tablespace

	- sessions.sql             - actual connections to the database 
	- session_history.sql      - get a summary over the last active sessions 
	- session_long_active.sql  - all session that are longer actvie 
	- session_longops.sql      - get information about long running sql statements
	- session_killed.sql       - get the process information for killed sessions
	- my_opt_settings.sql      -  Optimizer settings in my session
	- session_opt_settings.sql -  Optimizer settings in my session  - parameter 1 username

	- starttrace.sql      - start a trace of my session
	- stoptrace.sql       - stop trace of my session
	- trace_status.sql    - show all traces in the database

	- service_session.sql - sessions per service over all instances 
	- trans.sql           - running transactions in the database
	- undo.sql            - show activity on the undo segment
	- undo_stat.sql       - show statistic for the undo tablespace usage
	- open_trans.sql      - all longer open running transactions in the database - uncommited transaction!
	- bgprocess.sql       - Background Processe in the database
	- process.sql         - actual processes in the database  parameter 1 - name of the DB or OS User 
                                                             parameter 2 - if Y shows also internal processes

	- process_get.sql      - show the information about the session with this PID - parameter 1 PID
	- resource_manager.sql - show the information about the resource manager  
	- tempspace_usage.sql  - show processes using the temp tablespace
	- parallel.sql         - parallel sql informations
	
	- tns.sql              - show services and tns settings on services
	- tns_history.sql      - show services statistics for the last 12 hours (only services with some traffic)
	- taf.sql              - Check TAF settings of the connections
	- connection_pool.sql  - Show the Database Resident Connection Pooling (DRCP) Settings

	- locks.sql            - locks in the database - mode 6 is the blocker!
	- ddl_locks.sql        - check for DDL Locks

	- wait.sql             - waiting sessions
	- wait_text.sql        - text to a wait event - parameter 1 part of the event name
	- wait_get_name.sql    - search for a name of a wait event

	- latch.sql            - get Informations about the DB latch usage
	- checkpoint.sql       - get the actual status for the instance recovery

	- my_user.sql          - who am i and over with service i connect to the database
	- nls.sql              - global and session nls Settings
	- version.sql          - version of the database
	- test_sqlnet_fw.sql   - test the timeouts of SQL*Net

	- init.sql             - init.ora entries
	- init_rac.sql         - show init.parameter in a rac Environment to check if same parameters on each node
	- db_events.sql        - test if some events are set in the DB enviroment

	- xmldb.sql            - show configuration of the XML DB
	- acl.sql              - show the acls of the Database (for security)
	- my_acl.sql           - show my rights

	- invalid.sql          - show all invalid objects

	- user.sql             - rights and roles of a user and object grants - parameter 1 - Name of the user
	- users.sql            - overview over the DB users  - parameter 1 - Name of the user 	
	- user_ddl.sql         - get the script to create a user - parameter 1 - Name of the user
	- user_history.sql     - get some static information for the login behavior of this user -  Parameter 1 - Name of the user
	- user_objects.sql     - show the counts of objects from none default users

	- role.sql             - roles in the database - parameter 1 part of the role name
	- role_ddl.sql         - get the dll of one role in the databae - parameter 1 the role name

	- profile.sql          - profiles for the user of this database
	- proxy.sql            - proxy settings in the database
	- proxy_client.sql     - from which user you can connect to this user - parameter 1 the user

	- user_tab.sql         - get all the tables and views of a user - parameter 1 - part of the table name
	- ls.sql               - gets all the tables and shows the size of the user tab

	- comment.sql          - search over all comments                    - parameter 1 - part of the comment text
	
	- desc.sql             - describe a table - parameter 1 Tablename - 2 - part of the column name
	- tab.sql              - search a table or views in the database       - parameter 1 - part of the table
	- tab_cat.sql          - get the tables and views of the current user 
	- tab_count.sql        - count the entries in a table                 - parameter 1 - name of the table
	- tab_space.sql        - space usage of a table
	- tab_stat.sql         - get the statics of the table                 - parameter - Owner, Table name
	- tab_desc.sql         - describe the columns of the table            - parameter 1 - part of the table
	- tab_ddl.sql          - get the create script of a table             - parameter - Owner, Table name
	- tab_last.sql         - get the change date of a record in the table - parameter - Owner, Table name
	- tab_mod.sql          - get the last modifications of the table      - parameter - Owner, Table name
	- tab_data_changes.sql - get a % overview over the tables of a user - parameter - Owner
	
	- tab_usage.sql        - check if the table is used in the last time - parameter - Owner, Table name
	- tab_part.sql         - get the partition information of a table     - parameter - Owner, Table name
	
	- tab_ext.sql          - get information about external tables  
	- tab_iot.sql          - show information about a index organised table - parameter - Owner, Table name
	
	- tab_mat.sql          - Info about materialized views
	- tab_mat_log.sql      - Information about materialized views
	- refresh_group.sql    - Get all refresh groups of the DB for the  materialized views
	- my_refresh_group.sql - Get all refresh groups of your Schema
		
	- tab_defekt_blocks.sql           - check for corrupted blocks
	- tab_defekt_blocks_bad_table.sql - create rowid table for all readable data for a table with a defect lob segment
	
	- tab_redef.sql             - example for a online table redefinition
	- tab_stat_overview.sql     - statistic over all table of a user parameter 1 - schema name
	- analyse_changed_rows.sql  - anlayse changed row for a table
	
	- column_type.sql - get all columns in the database with this datatype parameter 1 - datatype - owner 
	- column.sql      - search all tables with this column name - parameter 1 - name of the column
	
	- synonym.sql        - search all synonym of a user - parameter - Owner, data type
	- synonym_detail.sql - get information over one synonym - parameter - Owner, synonym Name
	
	- lob.sql            - show the lob settings of the tables of the user - parameter - Owner
	
	- sequence.sql       - search a sequence in the database parameter 1 - name of the sequence
		
	- recycle.sql        - show the content summary of the dba recyclebin
	
	- tab_tablespace.sql        - get the tablespaces of the user    - parameter - Owner
	- tab_tablespace_all.sql    - get the used tablespace overview of this database 
	
	- tablespace_ddl.sql        - get the ddl of a tablespace, show default storage options! - parameter name of the tablespace
	- tablespace_space.sql      - get a overview over the free and used space for a tablespace - parameter name of the tablespace
	
	- index.sql       - get the information’s over a index            - parameter - Owner, Index name
	- index_all.sql   - get all indexes of a user                     - parameter - Owner,
	- index_mon.sql   - check the result of index monitoring   
	- index_ddl.sql   - get the DDL of an index
	
	- obj_dep.sql      - get the dependencies of a object in the database  - parameter - Owner, object name
	- obj_grants.sql   - get the grants for this object in the database    - parameter - Owner, object name
	- obj_last_ddl.sql - get the last ddl for all objects of a user        - parameter - Owner

	- plsql_info.sql   - information about a plsql function/package
	- plsql_depend.sql - information about the dependencies of a package/procedure  - parameter - Owner, object name
	- plsql_errors.sql - show the errors of pl/sql objects
	- plsql_dll.sql    - information about a plsql function/package       - parameter - Owner, object name
	- my_plsql.sql     - show all package of the current user
	
	- select.sql      - select first 3 records of the table as list - parameter 1 - name of the table
	- view_count.sql  - count entries in a view                     - parameter 1 - name of the view
	
	
	- asm.sql         - asm disk status and filling degree of the asm disks
	- asm_disk.sql    - asm disk space
	- asm_balance.sql - asm disk disk balance 
	- asm_partner.sql - Information about asm partner disk
	- flash.sql       - show the flash back information’s 
	- reco.sql        - recovery area settings and size
	
	- redo.sql        - redo log information
	- redo_change.sql - who create how much redo per day last 7 in the database
	- scn.sql         - scn in the archive log history 
	- sqn.sql         - sequence log
	
	
	- ext/tsc.sql       - table space size information
	- directory.sql     - show directories in the database
	- my_directory.sql  - show directories of the actual connect user  in the database
	- links.sql         - show the DB Links in the database
	- links_ddl.sql     - get the DDL of all DB links in the database
	
	- audit.sql         - show the audit settings 
	- audit_sum.sql     - auditlog summary
	- audit_login.sql   - audit the logins of users
	
	- jobs.sql          - jobs in the database job$ and scheduler tasks info
	- jobs_dbms.sql     - jobs declared with dbms_job - old style jobs
	- jobs_sheduler.sql - jobs declared over the job sheduler
	- jobs_errors.sql   - jobs in the database job$ and scheduler tasks info with errors
	- jobs_window_resource_class.sql - show the relation between job windows , job classes and resource plans
	- jobs_logs.sql     - Details of a job
	
	- sga.sql        - show information about the oracle sga usage 
	- buffer.sql     - show information about the buffer cache usage / must run as sys
	- pga.sql        - show information about the pga usage
	
	- statistic.sql  - show information over the statistics on the DB 
                      and stat age on tables and when the stats job runs

	- cursor.sql     - show information about the cursor usage

	- sql_find.sql   - find a sql Statement in the Cache - parameter 1 part of the sql statement
	- sql_plan.sql   - get the Execution Plan for one SQL ID from the cache
	- sql_temp.sql   - SQL that use the temp table space for sorting
	- sql_show_bind.sql  - Show the bind variables of the sql statement from the cursor Cache
	- sql_parallel.sql   - Show the parallel execution for this statement -  - parameter 1 - SQL ID

	- sql_kill_session.sql  - create the command to kill all sessions runing this sql at the moment - parameter 1 - SQL ID
	- sql_purge_cursor.sql  -  purge the cursor out of the cache  - parameter 1 - SQL ID

	- sql_profile.sql       - shwo all profiles in the database
	- sql_profile_details.sql - get the details of a sql profile - parameter 1 - Profile Name

	- get_plan.sql  - get the plan of the last "explain plan for"

	- ash.sql                 - usage of the acive session history ASH
	- awr.sql                 - usage of the AWR repository and of the SYSAUX table space 
	- awr_sql_find.sql        - find a sql Statement in the AWR History  - parameter 1 part of the sql statement
	- awr_sql_find_report.sql - ceate overview report over the usage of a sql statement or hint - parameter 1 part of the sql statement
	- awr_sql_stat.sql        - get statistic of the SQL execution of one statement - parameter 1 - SQL ID
	- awr_sql_hash.sql        - get the different hashes if exits                   - parameter 1 - SQL ID
	- awr_sql_plan.sql        - get plan of the SQL execution of one statement - parameter 1 - SQL ID
	- awr_sql_time_stat.sql   - get all sql statements from the awr for this time - parameter 1 - Startdate  - parameter 2 end date in DE format
	- awr_temp_usage.sql      - get the sql that use temp tablespace from the awr for this time - parameter 1 - Startdate  - parameter 2 end date in DE format
	- awr_pga_stat.sql        - statistic of the pga usage
	- awr_sys_stat.sql        - statistic of system historical statistics information
	- awr_session_stat.sql    - statistic of the sessions of a user
	- awr_session_resource_plan_historie.sql - Show the consumer group of all history active sessions of a user
	- awr_act_active_sessions.sql            - get information about the act active Session in the last 90 minutes
	- awr_act_blocking_sessions.sql          - get information about blocking sessions in the database
	- awr_session_none_technical_user.sql    - get information about none technical user sessions
	
	- calibrate_io.sql     - Use io calibrate to analyses io of the database and set the interal i/o views
	- system_stat.sql      - get the DB interal Systemstat values like workload statistic and i/o calibarate values
	
	- ctx.sql              - Oracle Text indexes for a user and ctx settings - parameter 1 - name of the user
	
	- rman.sql             - rman settings of this databasr and summary information about the last backups for this database and the block change tracking feature
	- rman_process.sql     - get information over running rman processes for tracing
	- rman_status.sql      - get the status of the last backup in the database
	
	- datapump.sql         - show datapump sessions
	
	- standby_status.sql   - status of a standby / DG enviroment
	
	- streams_status.sql   - status of streams replication
	- streams_config.sql   - streams configuration
	- streams_logs.sql     - show the streams archivelogs - which can be deleted 
	- streams_print_error.sql - print the SQL Statements for all LCRS in a transaction if a streams error ocurs
	- streams_print_lcr.sql   - print the LCR of one Message
	- streams_logmnr.sql      - information about the log miner process
	
	- db_alerts.sql           - get the internal metric settings of the db side monitoring 
	- db_alerts_set.sql       - set the threshold of a metric
	
	- health_mon.sql          - call the health monitoring in 11g - get the parameter 
		
	- login.sql               - set the login prompt
	
	#Create Scripts
	=================
	
	- clean_user.sql            - create the DDL to delete every object in the schema - parameter 1 - username
	
	- space_tablespace.sql      - create the DDL to shrink a table space - parameter 1 - Name of the table space (%) for all
	- space_tablespace_auto.sql - shrink each possible tablesspace without asking 								
	
	- recreate_index.sql        - Script to create a index recration script 
	- recreate_table.sql        - Script to reorganise all small tables in a tablespace, offline with !alter Table move!
	
	
	- create_mon_index.sql      - Script to create index enable or disable monitoring scripts for a user - parameter 1 - username
	
	#Reports
	=================
	
	- check_col_usage.sql - HTML Report - Table column used in SQL Statements but not indexed and all indexes with more than one column to check for duplicate indexing

	- top_sql.sql         - HTML Report - Top SQL Statements in the database for Buffer / CPU / Sort Usage
	- sql_user_report.sql - HTML Report - Show all sql statements for this user in the SGA 

	- audit_rep.sql       - HTML Report - Audit Log entries

	- licence.sql         - HTML Report - License Report Overview - Feature Usage

	#Setup
	=================

	- 01-db-setup/create_global_errorlog.sql    - create a global error table and error trigger + maintain job

	- 01-db-setup/delete_global_errorlog.sql    - delete the global error trigger + error table

	- 01-db-setup/create_audit_log_database.sql - create own table space for auditlog, move audit log to this table pace - create clean job

	#The OEM Query Scripts
	=================
	- get the the help of the OEM scripts use oem/help_oem.sql

-------------------------------------------------------------------------------
#

