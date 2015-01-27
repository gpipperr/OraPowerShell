--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the sql execution plan for this sql id from the AWR Repository
--         You need the Tuning Pack Licence to use the AWR! 
-- Date:   September 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

define SQL_ID = &1 

set verify off

SET linesize 250 pagesize 0 recsep OFF

ttitle left  "SQL Plan from AWR ID:  &SQL_ID." skip 2

select 
 * from 
TABLE(dbms_xplan.display_awr(sql_id=> '&SQL_ID.', format => 'TYPICAL'));

ttitle off
