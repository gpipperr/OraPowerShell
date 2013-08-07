--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script Overview
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

DOC 
-------------------------------------------------------------------------------
 
	The daily scripts
	
	- login.sql    -  set the login prompt
	- dict.sql     -  query the data dictionary - parameter 1 - part of the comments entry
	- status.sql   -  status of the instance/cluster instances
	- invalid.sql  -  show all invalid objects
	- asm.sql      -  asm disk status and filling degree of the asm disks
	- version.sql  -  version of the database
	- sessions.sql -  actual connections to the database 
	- reco.sql     -  recovery Area settings and size
	- tsc.sql      -  tablespace size information
	- space.sql    -  space usage of a table
	
	
	Reports
	
	check_col_usage.sql - HTML Report - Table column used in SQL Statments but not indexed
	                      and all indexes with more then one column to check for duplicate indexing
 
	
-------------------------------------------------------------------------------
#
