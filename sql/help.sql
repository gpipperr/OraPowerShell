--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script Overview
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

DOC 
-------------------------------------------------------------------------------
 
	The daily scripts
	
	- dict.sql     	-  query the data dictionary - parameter 1 - part of the comments text
	
	- status.sql   	-  status of the instance/cluster
	- sessions.sql 	-  actual connections to the database 
	- tns.sql       -  show services and tns settings on services
	- locks.sql     -  locks in the database - mode 6 is the blocker!
	- wait.sql      -  Waiting sessions
	
	- version.sql  	-  version of the database
	- invalid.sql  	-  show all invalid objects
	
	- jobs.sql      -  jobs in the database job$ and scheduler tasks info
	- user.sql      -  Rights and roles of a user and object grants - parameter 1 - Name of the user
	
	- asm.sql      	-  asm disk status and filling degree of the asm disks
	- reco.sql     	-  recovery area settings and size
	- redo.sql      -  redo log information
	- tsc.sql      	-  tablespace size information
	
	- directory.sql -  show directories in the database
	- links.sql     - show the DB Links in the database
	
	- sga.sql       -  show information about the oracle sga usage 
	- pga.sql       -  show information about the pga usage
	- awr.sql       -  usage of the AWR repository and of the SYSAUX tablepace 
	
	- statistic.sql  -  show information over the statistics on the DB and stat age on tables and when the stats job runs
	- cursor.sql     - show information about the coursor usage
	- find_sql.sql   - find a sql Statement in the Cache  - parameter 1 part of the sql statment
	- plan_sql.sql   - get the  Exection Plan for one SQL ID from the cache and from the awr repository
	
	- ctx.sql       - Oracle Text indexes for a user and ctx settings  - parameter 1 - name of the user
	
	- tab.sql       - search a table or view in the database     - parameter 1 - part of the table name
	- user_tab.sql  - get the tables and views of a user a list  - parameter 1 - name of the user
	- tab_space.sql - space usage of a table
	- tab_stat.sql  - get the statics of the table               - parameter 1 - part of the table name
	
	- login.sql    	-  set the login prompt
		
	Create Scripts
	
	- clean_user.sql       - create the DDL to delete every object in the schema - parameter 1 - username
	- space_tablespace.sql - create the DDL to shrink a tablespace - parameter 1 - Name of the tablespace (%) for all
	
	Reports
	
	- check_col_usage.sql - HTML Report - Table column used in SQL Statments but not indexed
	                        and all indexes with more then one column to check for duplicate indexing
	
	- top_sql.sql         - HTML Report - Top SQL Statements in the database for Buffer / CPU / Sort Usage						
 	
-------------------------------------------------------------------------------
#
