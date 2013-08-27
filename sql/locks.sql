--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script Locks overview
-- Date:   2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET pagesize 300
SET linesize 250
set echo off

ttitle left "Lock Overview in the database" skip 2

column obj_name       format a16 heading "Locked|Object"

column orauser        format a14 heading "Oracle|Username"
column os_user_name   format a14 heading "O/S|Username"

column ss       format a12 heading "SID:Ser#"
column time     format a16 heading "Logon|Date/Time" 
column procid   format a10 heading "Process|ID"
column machine  format a15 heading "PC Name|User"
column logMod   format 9   heading "=> 6|blocker!"


select owner || '.' || object_name as obj_name
      ,oracle_username || ' (' || s.status || ')' as orauser
      ,os_user_name
      ,machine
      ,l.process as procid
      ,s.sid || ',' || s.serial# as ss
      ,to_char(s.logon_time, 'dd.mm.yyyy hh24:mi') time
      --,l.LOCKED_MODE as logMod
     ,lc.lmode logMod
  from gv$locked_object l
      ,dba_objects      o
      ,gv$session       s
      ,gv$transaction   t
      ,gv$lock          lc
 where l.object_id = o.object_id
   and s.sid     = l.session_id
   and s.inst_id = l.inst_id
   and s.taddr   = t.addr    (+)
   and s.inst_id = t.inst_id (+)
   and s.sid     = lc.sid 
   and lc.type = 'TX'
   and s.inst_id   = lc.inst_id   
 order by oracle_username
         ,ss
         ,obj_name
         ,s.logon_time
/

ttitle off
