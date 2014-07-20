--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- desc get all deployed target types in the Repository
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 240 pagesize 400 recsep OFF

prompt
prompt get all target types in the OEM Repostiory with a target
prompt 

column target_type format a40 heading "Target Types"
column tg_count    format 9G999 heading "Count of|targets"

select target_type
    ,  count(*) as tg_count
  from sysman.em_targets 
 group by target_type
/




