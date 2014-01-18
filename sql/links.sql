--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   DB Links
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
	  ,host
from dba_db_links
 /

 
ttitle off

prompt ... to create a private db link use this statement:
prompt ... "CREATE DATABASE LINK mylink CONNECT TO remote_user IDENTIFIED BY remote_pwd USING 'remote_db';"

