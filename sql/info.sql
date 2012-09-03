--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   spool metainfos from the database (backup!)
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================


spool &1

spool 

set pagesize 200

column name format a60
column parameter format a40
column value format a30
column property_value format a30
column property_name format a30
column tablespace_name format a20
column FLASHBACK_ON format a40
column LOG_MODE format a20
-------------- version -----------------
ttitle  "---------#####version---------#####"  skip 2
select * from v$version;
select * from v$option;

------- patchlevel ------
ttitle  "---------#####patchlevel---------#####"  skip 2
select * from sys.registry$history;

------- properties ------
ttitle  "---------#####properties---------#####"  skip 2
select property_name,property_value from database_properties;

------- charset ----------
ttitle  "---------#####charset---------#####"  skip 2
select * from nls_database_parameters;

----- dbid ----------
ttitle  "---------#####dbid---------#####"  skip 2
select name,dbid from v$database;

----- datastructur ------
ttitle  "---------#####datastructur---------#####"  skip 2
select name as datafile_name from v$datafile;
select name as tempfile_name from v$tempfile;
select member as logfile_name from v$logfile;
select tablespace_name,block_size from dba_tablespaces order by tablespace_name;

------ archive -----------
ttitle  "---------#####archive and flashback---------#####"  skip 2

archive log list

select FLASHBACK_ON,LOG_MODE from v$database;

spool off
exit;
