--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get Information over the usage of resources of the database
-- Date:   November 2013

-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF

ttitle  "Resource Limit Informations"  SKIP 2

column INST_ID             format 9999   heading "INST|ID"   
column RESOURCE_NAME       format a25    heading "Resource|Name"              
column CURRENT_UTILIZATION format 999999 heading "Act|Usage"   
column MAX_UTILIZATION     format 999999 heading "Max|Usage"   
column INITIAL_ALLOCATION  format 999999 heading "Init|Value"            
column LIMIT_VALUE         format 999999 heading "Limit|Value"


select * 
  from GV$RESOURCE_LIMIT
order by 1,3 desc  
/

ttitle off

