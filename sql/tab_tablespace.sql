--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   
-- Date:   November 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify  off
set linesize 120 pagesize 4000 recsep OFF

define USER_NAME = '&1' 

prompt
prompt Parameter 1 = User  Name          => &&USER_NAME.
prompt

BREAK ON tablespace_name

column tablespace_name format a32 heading "Tablespace Name"
column segment_type    format a20 heading "Segment Type"
column count_          format 99999 heading "Count"

select  tablespace_name
      , segment_type
		, '::' as "|"
		, count(*) as count_ 
 from dba_segments 
where owner like upper('&&USER_NAME')
group by tablespace_name,segment_type
order by tablespace_name,segment_type
/
