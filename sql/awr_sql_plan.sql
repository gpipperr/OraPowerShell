--==============================================================================
--
-- Desc:   get the sql execution plan for this sql id from the AWR Repository
--         You need the Tuning Pack Licence to use the AWR! 
-- Date:   September 2013
--
--==============================================================================
set linesize 130 pagesize 0 recsep off
set verify off



define SQL_ID = &1
 
ttitle left  "SQL Plan from AWR ID:  &SQL_ID." skip 2

select 
 * from 
TABLE(dbms_xplan.display_awr(sql_id=> '&SQL_ID.', format => 'TYPICAL'));

ttitle off
