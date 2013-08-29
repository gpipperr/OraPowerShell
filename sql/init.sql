--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   check init.ora parameter
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify  off
set linesize 120 pagesize 4000 recsep OFF

prompt
prompt Parameter 1 = DB Parameter          => '&1' 
prompt

define PARA_NAME = '&1' 

ttitle left  "init.ora parameter" skip 2

column inst_id      format 99  heading "In|Id"
column name         format a32 heading "Parameter"
column value        format a40 heading "Value"
column isdefault        format a2  heading "De"
column isses_modifiable format a2  heading "Se"
column issys_modifiable format a2  heading "Sy"
column ismodified       format a2  heading "Mo"
column isadjusted       format a2  heading "Ad"
column isdeprecated     format a2  heading "Dp"
column isbasic          format a2  heading "Ba"
column isinstance_modifiable format a1  heading "Im"


select inst_id
     , name
	 , value
	 , decode(isdefault,'TRUE','Y','FALSE','-',isdefault)                as isdefault
	 , decode(isses_modifiable,'TRUE','Y','FALSE','-',isses_modifiable)  as isses_modifiable
	 , decode(issys_modifiable,'TRUE','Y','IMMEDIATE','I','DEFERRED','D','FALSE','-',issys_modifiable) as issys_modifiable
	 , decode(isinstance_modifiable,'TRUE','Y','FALSE','-',isinstance_modifiable)       as isinstance_modifiable
	 , decode(ismodified,'TRUE','Y','MODIFIED','M','SYSTEM_MOD','S','FALSE','-',ismodified)     as ismodified
	 , decode(isadjusted,'TRUE','Y','FALSE','-',isadjusted)     as isadjusted
	 , decode(isdeprecated,'TRUE','Y','FALSE','-',isdeprecated) as isdeprecated
	 , decode(isbasic,'TRUE','Y','FALSE','-',isbasic)           as isbasic
 from gv$parameter 
where name like lower('%&&PARA_NAME.%')
order by 1 
/

prompt ....
prompt .... column  "De" = is default
prompt .... column  "Se" = can be changed with alter session 
prompt .... column  "Sy" = can be changed with alter system => I = change will work immediately | D = only new sessions
prompt .... column  "Im" = can be changed for one instance in a cluster
prompt .... column  "Mo" = has been modified after instance startup => M = alter session | S=alter system
prompt .... column  "Ad" = is adjusted internaly by oracle
prompt .... column  "Dp" = is deprecated 
prompt .... column  "Ba" = is basic parameter
prompt ....
prompt .... to adjust : alter system set <parameter>=<value> scope=both|memory|spfile sid='*'
prompt ....

ttitle off
