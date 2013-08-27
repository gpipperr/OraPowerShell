--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   actual connections to the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

define USER_NAME   =  &1
define ALL_PROCESS = '&2'

prompt
prompt Parameter 1 = Username          => &&USER_NAME.
prompt Parameter 2 = to Show all use Y => &&ALL_PROCESS.
prompt

set verify off

SET linesize 130 pagesize 300 recsep OFF

ttitle left  "All User Sessions on this DB" skip 2


column inst_id    format 99     heading "Inst|ID"
column username   format a8     heading "DB User|name"
column sid        format 99999  heading "SID"
column serial#    format 99999  heading "Serial"
column machine    format a14    heading "Remote|pc/server"
column terminal   format a14    heading "Remote|terminal"
column program    format a17    heading "Remote|program"
column module     format a15    heading "Remote|module"
column client_info format a15   heading "Client|info"
column client_identifier format A15 heading "Client|identifier"

select  inst_id 
      , sid
	  , serial#
      , username
	  , machine
      , terminal
      , program
	  , module
      , client_identifier
	  , client_info
  from gv$session 
 where  ( username like '%&&USER_NAME.%' or ( nvl('&ALL_PROCESS.','N')='Y' and username is  null))
 order by program
         ,inst_id
/

ttitle left  "User Sessions Summary on this DB" skip 2

column cs format 999
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

prompt
prompt ... to kill session     "ALTER SYSTEM KILL SESSION 'sid,serial#,@inst_id';"
prompt ... to end  session     "ALTER SYSTEM DISCONNECT SESSION 'sid,serial#' IMMEDIATE;"
prompt
