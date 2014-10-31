--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   version of the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
-- see Script to Collect DB Upgrade/Migrate Diagnostic Information (dbupgdiag.sql) (Doc ID 556610.1)
--

SET linesize 240 pagesize 400 recsep OFF

ttitle left  "DB Infos -- Version" skip 2

select banner from v$version
/

ttitle left  "DB Infos -- DB Bit Version" skip 2
SELECT distinct('DB Bit Version:: '|| (length(addr)*4) || '-bit database') "WordSize" 
FROM v$process
/


ttitle left  "DB Infos -- DB OS Version" skip 2

column OS_VER format a30 heading "DB OS Version"

select dbms_utility.port_string as os_ver from dual
/


ttitle left  "DB Infos -- Compatibility" skip 2

column Compatible format a35

SELECT 'Compatibility is set to :: '||value Compatible 
FROM v$parameter WHERE name ='compatible'
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

ttitle left  "DB Infos -- check for Oracle Label Security" skip 2

column labelsec format a60 heading "Oracle Label Security Check" 

SELECT case count(schema)
WHEN 0 THEN 'Oracle Label Security is NOT installed at database level'
ELSE 'Oracle Label Security is installed '
END  as labelsec
FROM dba_registry
WHERE schema='LBACSYS'
/

prompt Check for Patches ....
prompt
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

ttitle left  "DB Infos -- Timezone" skip 2
column version format 99
SELECT version from v$timezone_file;


ttitle off
