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
	
	- dict.sql       - query the data dictionary - parameter 1 - part of the comments text
	
	- database.sql   - name and age of the database
	- status.sql     - status of the instance/cluster
	- instance.sql   - status of the instance where the user is connected
	- limit.sql      - resource limits since last startup of the instances

	- sessions.sql   - actual connections to the database 
	- service_session.sql - sessions per service over all instances 
	- trans.sql      - running transactions in the database
	- undo.sql       - show activity on the undo segment
	- open_trans.sql - all longer open running transactions in the database
	- process.sql    - actual processes in the database  
							  parameter 1 - name of the DB or OS User 
							  parameter 2 - if Y shows also internal processes
	- resource_manager.sql - show the information about the resource manager  
	- tempspace_usage.sql- show processes using the temp tablespace					
	
	- tns.sql        - show services and tns settings on services
		
	- locks.sql      - locks in the database - mode 6 is the blocker!
	- wait.sql       - waiting sessions
		
	- nls.sql        - global and session nls Settings
	- version.sql  	 - version of the database
	
	- init.sql       - init.ora entries
	- init_rac.sql   - show init.parameter in a rac Environment to check if same parameters on each node
	- db_events.sql  - test if some events are set in the DB enviroment
	
	- xmldb.sql      - show configuration of the XML DB
	- acl.sql        - show the acls of the Database (for security)
	
	- invalid.sql  	 - show all invalid objects
	
	- user.sql       - rights and roles of a user and object grants - parameter 1 - Name of the user
	- users.sql      - overview over the DB users
	- user_history.sql - get some static information for the login behavior of this user 
	                     parameter 1 - Name of the user
	- role.sql         - roles in the database					 
	- user_objects.sql - show the counts of objects from none default users
	- profile.sql    - profiles for the user of this database
	- proxy.sql      - proxy settings in the database
	
	
	- user_tab.sql   - get all the tables and views of a user - parameter 1 - part of the table name
	- ls.sql         - gets all the tables and shows the size of the user tab
	- tab_cat.sql    - get the tables and views of the current user 
	- tab_count.sql  - count the entries in a table                 - parameter 1 - name of the table
	- tab.sql        - search a table or views in the database       - parameter 1 - part of the table
	- tab_space.sql  - space usage of a table
	- tab_stat.sql   - get the statics of the table                 - parameter 1 - part of the table
	- tab_desc.sql   - describe the columns of the table            - parameter 1 - part of the table
	- tab_ddl.sql    - get the create script of a table             - parameter - Owner, Table name
	- tab_last.sql   - get the change date of a record in the table - parameter - Owner, Table name
	- tab_mod.sql    - get the last modifications of the table      - parameter - Owner, Table name
	- column_tyle.sql - get all columns in the database wiht this datatype  parameter 1 - datatype
	- column.sql      - search all tables with this column name - parameter 1 - name of the column
	- analyse_changed_rows.sql  - anlayse changed row for a table
	- tab_redef.sql   - example for a online table redefination
	- tab_stat_overview.sql - statistic over all table of a user parameter 1 - schema name
	
	- recycle.sql    - show the content summary of the dba recyclebin
	
	- tab_tablespace.sql      - get the tablespaces of the  user    - parameter - Owner
	- tab_tablespace_all.sql  - get the used tablespace overview of this database 
	
	- index.sql		 - get the informations over a index            - parameter - Owner, Index name
	- obj_dep.sql    - get the dependencies of a object in the database  - parameter - Owner, object name
	
	- plsql_info.sql  - information about a plsql function/package
	
	- select.sql     - select first 3 records of the table as list  - parameter 1 - name of the table
	- view_count.sql - count entries in a view                      - parameter 1 - name of the view
	- comment.sql    - search over all comments                     - parameter 1 - part of the comment text
	
	- asm.sql      	 - asm disk status and filling degree of the asm disks
	- asm_disk.sql     - asm disk space
	- asm_balance.sql - asm disk disk balance 
	- flash.sql      - show the flash back information?s 
	- reco.sql     	 - recovery area settings and size
	
	- redo.sql       - redo log information
	- redo_change.sql - how create how much redo per day last 7 in the database
	- scn.sql        - scn in the archive log history 
	- sqn.sql        - squence log
	
	- tsc.sql      	- table space size information
	- awr.sql        - usage of the AWR repository and of the SYSAUX table pace 
	- awr_sql.sql    - get SQL information
	
	- directory.sql  - show directories in the database
	- links.sql      - show the DB Links in the database
	
	- audit.sql      - show the audit settings 
	- audit_sum.sql  - auditlog summary
			
	- jobs.sql       - jobs in the database job$ and scheduler tasks info
	
	- sga.sql        - show information about the oracle sga usage 
	- buffer.sql     - show information about the buffer cache usage / must run as sys
	- pga.sql        - show information about the pga usage
		
	- statistic.sql  - show information over the statistics on the DB 
	                   and stat age on tables and when the stats job runs
	- cursor.sql     - show information about the cursor usage
	- find_sql.sql   - find a sql Statement in the Cache - parameter 1 part of the sql statement
	- plan_sql.sql   - get the Execution Plan for one SQL ID from the cache and from the awr repository
	- temp_sql.sql   - SQL that use the temp table space for sorting
	
		
	- test_io.sql    - Use io calibrate to analyses io of the database
	
	- ctx.sql        - Oracle Text indexes for a user and ctx settings  - parameter 1 - name of the user
	
	- rman.sql       - rman settings of this database 
	                   and summary information about the last backups for this database
	- rman_process.sql - get information over running rman prozesses for tracing
	
	- datapump.sql    - show datapump sessions
	
	- streams_status.sql - Status of streams replication
	- streams_config.sql - streams configuration
	- streams_logs.sql   - show the streams archivelogs - which can be deleted 
	
	- login.sql    	  - set the login prompt
		
	#Create Scripts
	=================
	
	- clean_user.sql       - create the DDL to delete every object in the schema - parameter 1 - username
	- space_tablespace.sql - create the DDL to shrink a table space
	                         parameter 1 - Name of the table space (%) for all
	- recreate_index.sql   - Script to create a index recration script								 
	
	#Reports
	=================
	
	- check_col_usage.sql - HTML Report - Table column used in SQL Statements but not indexed
	                        and all indexes with more than one column to check for duplicate indexing
	
	- top_sql.sql		  - HTML Report - Top SQL Statements in the database for Buffer / CPU / Sort Usage		
	
	- audit_rep.sql		  - HTML Report - Audit Log entries
	
   - licence.sql		  - HTML Report - Licence Report Overview - Feature Usage
	
	#Setup
	=================
	
	- 01-db-setup/create_global_errorlog.sql
	            - create a global error table and error trigger + maintain job
						 
 	- 01-db-setup/delete_global_errorlog.sql
					- delete the global error trigger + error table
						
	- 01-db-setup/create_audit_log_database.sql					
					- create own table space for auditlog, move audit log to this table pace - create clean job

-------------------------------------------------------------------------------
#

