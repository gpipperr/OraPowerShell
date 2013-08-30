--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script Overview
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

-- FIX IT
-- umbauen auf REGEXP_SUBSTR(table_name,'_+,') um dba_,all_,user_ anzuzeigen
--

set  verify off

column table_name format a30
column comments   format a85

select table_name,comments
  from dict
 where lower(comments) like lower('%&1.%')
   and table_name like 'DBA%'
/

set  verify on
