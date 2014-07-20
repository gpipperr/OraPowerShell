--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   DB Links DDL

--==============================================================================

SET linesize 240 pagesize 4000 recsep OFF

set long 1000000

ttitle left  "create DDL for all DB Links in the Database" skip 2

select '-- DBLINK OWNER : '||owner||chr(10)||chr(13)||dbms_metadata.get_ddl('DB_LINK',db_link,owner ) ||';'||chr(10)||chr(13) as stmt
from dba_db_links
 /

 
ttitle off

