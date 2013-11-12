--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script Overview
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

DOC 
-------------------------------------------------------------------------------
 
	The daily scripts
	
	- dict.sql       - query the data dictionary - parameter 1 - part of the comments text
	
	- database.sql   - name and age of the database
	- status.sql     - status of the instance/cluster
	- instance.sql   - status of the instance where the user is connected
	- limit.sql      - limits since last startup of the instances

	- sessions.sql   - actual connections to the database 
	- trans.sql      - running transactions in the database
	- process.sql    - actual processes in the database  
	                   Parameter 1 - name of the DB or OS User - parameter 2 - if Y shows also internal processes
	
	- tns.sql        - show services and tns settings on services
		
	- locks.sql      - locks in the database - mode 6 is the blocker!
	- wait.sql       - waiting sessions
		
	- nls.sql        - global and session nls Settings
	- version.sql  	 - version of the database
	
	- init.sql       - init.ora entries
	- init_rac.sql   - show init.parameter in a rac Environment to check if same parameters on each node
	
	- xmldb.sql      - show configuration of the XML DB
	
	- invalid.sql  	 - show all invalid objects
	
	- user.sql       - rights and roles of a user and object grants - parameter 1 - Name of the user
	- users.sql      - overview over the DB users
	- user_history.sql - get some static information for the login behavior of this user - parameter 1 - Name of the user
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
	- index.sql		 - get the informations over a index            - parameter - Owner, Index name
	- obj_dep.sql    - get the dependencies of a object in the database  - parameter - Owner, object name
	
	- select.sql     - select first 3 records of the table as list  - parameter 1 - name of the table
	- view_count.sql - count entries in a view                      - parameter 1 - name of the view
	- comment.sql    - search over all comments                     - parameter 1 - part of the comment text
	
	- asm.sql      	 - asm disk status and filling degree of the asm disks
	- reco.sql     	 - recovery area settings and size
	- redo.sql       - redo log information
	- flash.sql      - show the flash back information?s 
	- tsc.sql      	 - table space size information
	- awr.sql        - usage of the AWR repository and of the SYSAUX table pace 
	- directory.sql  - show directories in the database
	- links.sql      - show the DB Links in the database
	- audit.sql      - show the audit settings 
	- audit_sum.sql  - auditlog summary
			
	- jobs.sql       - jobs in the database job$ and scheduler tasks info
	
	- sga.sql        - show information about the oracle sga usage 
	- buffer.sql     - show information about the buffer cache usage / must run as sys
	- pga.sql        - show information about the pga usage
		
	- statistic.sql - show information over the statistics on the DB and stat age on tables and when the stats job runs
	- cursor.sql     - show information about the cursor usage
	- find_sql.sql   - find a sql Statement in the Cache - parameter 1 part of the sql statement
	- plan_sql.sql   - get the Execution Plan for one SQL ID from the cache and from the awr repository
	- temp_sql.sql   - SQL that use the temp table space for sorting
		
	- test_io.sql    - Use io calibrate to analyses io of the database
	
	- ctx.sql        - Oracle Text indexes for a user and ctx settings  - parameter 1 - name of the user
	
	- rman.sql       - rman settings of this database and summary information about the last backups for this database
	
	- login.sql    	 - set the login prompt
		
	#Create Scripts
	
	- clean_user.sql       - create the DDL to delete every object in the schema - parameter 1 - username
	- space_tablespace.sql - create the DDL to shrink a table space - parameter 1 - Name of the table space (%) for all
	
	#Reports
	
	- check_col_usage.sql - HTML Report - Table column used in SQL Statements but not indexed
	                        and all indexes with more than one column to check for duplicate indexing
	
	- top_sql.sql         - HTML Report - Top SQL Statements in the database for Buffer / CPU / Sort Usage		
	
	- audit_rep.sql	      - HTML Report - Audit Log entries
		
	- licence.sql         - HTML Report - Licence Report Overview - Feature Usage
	
	#Setup
	
	- 01-db-setup/create_global_errorlog.sql
	                     - create a global error table and error trigger + maintain job
						 
 	- 01-db-setup/delete_global_errorlog.sql
						- delete the global error trigger + error table
						
	- 01-db-setup/create_audit_log_database.sql					
						- create own table space for auditlog, move audit log to this table pace - create clean job

-------------------------------------------------------------------------------
#

