--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the tablespaces of all the users
-- Date:   November 2013

-- Site:   http://orapowershell.codeplex.com
--==============================================================================


set verify  off
set linesize 120 pagesize 4000 recsep OFF

column tablespace_name format a32 heading "Tablespace Name"
column segment_type    format a20 heading "Segment Type"
column count_          format 99999 heading "Count"

BREAK ON owner

select   owner
      ,  tablespace_name
      , segment_type
		, '::' as "|"
		, count(*) as count_ 
 from dba_segments 
group by tablespace_name,segment_type,owner
order by owner,tablespace_name,segment_type
/

