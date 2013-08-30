--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   List tables 
-- Date:   01.September 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify  off
set linesize 120 pagesize 4000 recsep OFF

define TAB_NAME = '&1' 

prompt
prompt Parameter 1 = view Name          => &&TAB_NAME.
prompt

ttitle left  "Count views entries" skip 2

column count_rows   format 9999999  heading "Count|rows"


select count(*) as count_rows from &&TAB_NAME 
/ 

prompt
prompt

ttitle off