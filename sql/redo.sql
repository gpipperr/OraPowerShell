--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the user rights and grants
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF

ttitle  "Report Redo Log Configuration "  SKIP 1  - 
left "Sizes in MB" SKIP 2
			 
column member format a50
column THREAD# format 99
column  GROUP# format 99

ttitle  "Redolog  Size of each group"  SKIP 1  - 
left "Sizes in MB" SKIP 2

select count(*)
      ,thread#
      ,to_char(round(BYTES / 1024 / 1024, 2)) || 'M' as REDOLOG_SIZE
  from v$log
 group by thread#
         ,BYTES
/

prompt

ttitle  "Redolog  Status of each group"  SKIP 1  -
left "Sizes in MB" SKIP 2

select THREAD#
      ,group#
      ,status
      ,to_char(round(BYTES / 1024 / 1024, 2)) || 'M' as REDOLOG_SIZE
  from v$log
 order by 1
         ,2
/
prompt

ttitle  "Redolog Member  of the groups"  SKIP 1  -
left "Sizes in MB" SKIP 2

select group#
      ,member
      ,status
  from v$logfile
 order by 1
         ,2
/	

ttitle  "Redolog Switch frequency "  SKIP 1

select to_char(FIRST_TIME,'dd.mm.yyyy hh24:mi:ss') as first_time_log
      , RECID
	  , THREAD#
	  , SEQUENCE#
  from (select * from v$log_history order by recid desc) 
where rownum <=20
order by first_time_log asc
/




ttitle off

prompt



