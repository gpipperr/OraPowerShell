--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script Overview
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

DOC 
-------------------------------------------------------------------------------
 
	The daily scripts
	
	- dict.sql     	-  query the data dictionary - parameter 1 - part of the comments entry
	
	- status.sql   	-  status of the instance/cluster instances
	- sessions.sql 	-  actual connections to the database 
	- locks.sql     -  locks in the database - mode 6 is the blocker!
	- wait.sql      -  Waiting sessions
	
	- version.sql  	-  version of the database
	- invalid.sql  	-  show all invalid objects
	
	- jobs.sql      -  jobs in the database job$ and scheduler tasks info
	- user.sql      -  Rights and roles of a user and object grants - parameter 1 - Name of the user
	
	- asm.sql      	-  asm disk status and filling degree of the asm disks
	- reco.sql     	-  recovery Area settings and size
	- redo.sql      -  redo log information
	- tsc.sql      	-  tablespace size information
	- space.sql    	-  space usage of a table
	- directory.sql -  show directories in the database
	
	- login.sql    	-  set the login prompt
	
	Create Scripts
	
	- clean_user.sql      - create the DDL to delete every object in the schema - parameter 1 - username
	
	Reports
	
	- check_col_usage.sql - HTML Report - Table column used in SQL Statments but not indexed
	                        and all indexes with more then one column to check for duplicate indexing
 
	
-------------------------------------------------------------------------------
#
