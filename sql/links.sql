--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:    SQL Script Overview
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 240 pagesize 400 recsep OFF
ttitle left  "Link Infos -- DB Links this user can see " skip 2

column owner format a10
column host  format a60
column db_link format a20
column username format a20


select db_link
      ,host
	  ,owner 
	  ,username
from all_db_links
 /

ttitle off

ttitle left  "Link Infos -- All DB Links" skip 2

select db_link
	  ,owner 
from dba_db_links
 /

ttitle off

