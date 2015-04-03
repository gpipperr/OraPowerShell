--==============================================================================
--
-- Desc:   undo usage
-- Date:   November 2013
--
--==============================================================================
set verify off
set linesize 130 pagesize 300 recsep off

show parameter undo


column name format a30
column status format a20
column username format a20
column sid format 99999999

select  a.name
     ,  b.status 
	  ,  d.username 
	  ,  d.sid 
	  ,  d.serial#
	  ,  d.inst_id
from    v$rollname a
     , v$rollstat b
	  , gv$transaction c 
	  , gv$session d
where  a.usn = b.usn
  and  a.usn = c.xidusn
  and  c.ses_addr = d.saddr
  and c.inst_id=d.inst_id
  and a.name in ( 
		select segment_name
		 from dba_segments 
		 where tablespace_name like 'UNDO%'
    )
/		 
