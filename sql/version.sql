--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   version of the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 240 pagesize 400 recsep OFF

ttitle left  "DB Infos -- Version" skip 2

select banner
 from v$version
/

ttitle left  "DB Infos -- installed components" skip 2
column comp_name format a40
column status format a8
column version format a12
column schema format a12

select comp_name
     , status 
	 , version
	 , schema
from dba_registry
/

ttitle left  "DB Infos -- last Patches" skip 2

column ACTION_TIME format a10
column ACTION      format a8
column NAMESPACE   format a8
column VERSION     format a10
column ID            format a20
column COMMENTS       format a20
column BUNDLE_SERIES  format a6

select  to_char(ACTION_TIME,'dd.mm.yyyy') as ACTION_TIME
      , ACTION
	  , NAMESPACE
	  , VERSION
	  , COMMENTS
 from registry$history
order by ACTION_TIME desc
/

ttitle off