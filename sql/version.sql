--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   version of the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 240 pagesize 400 recsep OFF

ttitle left  "DB Infos -- Version" skip 2

select banner from v$version
/

ttitle left  "DB Infos -- installed components" skip 2
column comp_name format a40
column status format a8
column version format a12
column schema format a12

select comp_name
      ,status
      ,version
      ,schema
  from dba_registry
/

ttitle left  "DB Infos -- last Patches" skip 2

column a_time      format a10
column action      format a16
column namespace   format a8
column version     format a10
column id          format a20
column comments    format a35
column bundle_series  format a6

select to_char(action_time, 'dd.mm.yyyy') as a_time
      ,action
      ,namespace
      ,version
      ,comments
  from sys.registry$history
 order by action_time desc
/

ttitle off
