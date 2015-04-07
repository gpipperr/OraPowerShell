--==============================================================================
-- GPI - Gunther Pippèrr
-- Desc: Get all refresh groups of your Schema
--==============================================================================
set linesize 130 pagesize 300 recsep off

column owner        format a20
column mview_name   format a25 
column last_refresh_date format a18
column rname         format a20
column next_date    format a18

select mv.owner
      , mv.mview_name
	  , to_char(mv.last_refresh_date,'dd.mm.yyyy hh24:mi') as last_refresh_date
	  , rc.rname
	  , to_char(rc.next_date,'dd.mm.yyyy hh24:mi') as next_date
from user_mviews mv
    , user_refresh_children rc
where mv.owner = rc.owner (+)
  and mv.mview_name  = rc.name  (+)	 
/  