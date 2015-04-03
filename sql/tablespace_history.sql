--==============================================================================
--
-- Desc:   
-- Date:   November 2013
--
--==============================================================================

prompt You need the diagnostic pack for this feature

set verify off
set linesize 130 pagesize 300 recsep off

select to_char (sp.begin_interval_time,'dd.mm.yyyy') "tag"
   , tbstat.tsname tsname
   , max(round((tbus.tablespace_usedsize * tbs.block_size )/(1024*1024),1)) belegt_mb
   , max(round((tbus.tablespace_size     * tbs.block_size )/(1024*1024),1)) groesse_mb
from dba_hist_snapshot sp
   , dba_tablespaces   tbs
   , dba_hist_tbspc_space_usage tbus
   , dba_hist_tablespace_stat   tbstat
where tbus.tablespace_id = tbstat.ts#
  and tbus.snap_id       = sp.snap_id
  and tbstat.tsname      = tbs.tablespace_name
group by to_char (sp.begin_interval_time,'dd.mm.yyyy')
    , tbstat.tsname
order by tbstat.tsname
        , "tag"
/

