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
column ACTION_TIME format a10
column ACTION      format a8
column NAMESPACE   format a8
column VERSION     format a10
column ID            format a20
column COMMENTS       format a20
column BUNDLE_SERIES  format a6
column comp_name format a40
column status format a8
column version format a12
column schema format a12


-------------- version -----------------
ttitle  "---------#####version---------#####"  skip 2
select * from v$version;

select * from v$option;

select comp_name
     , status 
	 , version
	 , schema
from dba_registry
/

------- patchlevel ------
ttitle  "---------#####patchlevel---------#####"  skip 2

select  to_char(ACTION_TIME,'dd.mm.yyyy') as ACTION_TIME
      , ACTION
	  , NAMESPACE
	  , VERSION
	  , COMMENTS
	  , BUNDLE_SERIES
 from registry$history
order by ACTION_TIME desc
/

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
