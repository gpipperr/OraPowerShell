--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   actual connections to the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF

ttitle left  "User Sessions on this DB" skip 2


column username format A15
column terminal format A15
column program  format A20
column client_identifier format A25
column cs format 999
column INST format 999

select inst_id as INST
      ,username
      ,terminal
      ,program
      ,client_identifier
  from gv$session
 where username is not null
 order by program
         ,inst_id
/

ttitle left  "User Sessions Summary on this DB" skip 2

column program  format A40
select count(*) as cs
      ,username
      ,program
  from gv$session
 where username is not null
 group by username
         ,program
 order by username
/

ttitle off
