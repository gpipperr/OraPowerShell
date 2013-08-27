--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the sql execution plan for this sql id from the AWR Repository
--         You need the Tuning Pack Licence to use the AWR! 
-- Date:   September 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

define SQL_ID = &1 

set verify off

SET linesize 120 pagesize 400 recsep OFF

ttitle left  "SQL Plan from Cursor Cache ID:  &SQL_ID." skip 2

column out_put format a100 heading "SQL Plan Output"

select 
 PLAN_TABLE_OUTPUT as out_put
 from 
TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&SQL_ID.'));


ttitle left  "SQL Plan from AWR ID:  &SQL_ID." skip 2

select 
 * from 
TABLE(dbms_xplan.display_awr('&SQL_ID.'));

ttitle off
