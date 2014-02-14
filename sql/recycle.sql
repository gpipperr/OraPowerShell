--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   recyle bin informatoins
-- Date:   02.2014
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set pagesize 300
set linesize 150
set verify off

column owner format a15 heading "Owner"
column TYPE  format a12 heading "Obj|type"

column max_CREATETIME format a14 heading "Min|Create"
column min_CREATETIME format a14 heading "Max|Create"
column min_DROPTIME   format a14 heading "Min Age|Drop"
column max_DROPTIME   format a14 heading "Max Age|Drop"
column SPACE_GB       format 999G999D99 heading "Space|GB"

define BLOCK_SIZE=8192


select owner
	  , TYPE
	  , substr(min(CREATETIME),1,13)  as min_CREATETIME
	  , substr(max(CREATETIME),1,13)  as max_CREATETIME
	  , substr(min(DROPTIME),1,13)    as min_DROPTIME
	  , substr(max(DROPTIME),1,13)    as max_DROPTIME
	  , round((sum(space)/1024/1024/1024)*&&BLOCK_SIZE,2) as SPACE_GB
 from DBA_RECYCLEBIN
group by owner
       , type
order by 1,2		 
/		 

prompt .....
prompt ..... to clean all:  PURGE DBA_RECYCLEBIN; ( as sys user!)
prompt .....