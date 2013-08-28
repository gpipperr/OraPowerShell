--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   show flash features
--
-- Must be run with dba privileges
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF

ttitle  "Report Flashback Feature of the Database"  SKIP 2 -

column  FLASHBACK_ON format A20
	   
select FLASHBACK_ON 
  from V$DATABASE
/	   

column  INST_ID format A4
column  RETENTION_TARGET format A20
column  FLASH_SIZE format A20
column  ESTIMATED_SIZE format A20

ttitle  "Report Flashback Size of the Database"  SKIP 2 -


select 
   to_char(INST_ID) as inst_id
 , RETENTION_TARGET ||' Minuten'  RETENTION_TARGET
 , round((FLASHBACK_SIZE)/1024/1024) ||' MB' FLASH_SIZE
 , round((ESTIMATED_FLASHBACK_SIZE)/1024/1024)||' MB' ESTIMATED_SIZE
 from GV$FLASHBACK_DATABASE_LOG 
/


ttitle  "Report Flashback Logs of the Database"  SKIP 2 -
  
column  last_first_time format A20
column  maxsize format A10
select  to_char(INST_ID) as inst_id
	  ,max(LOG#) as last_logid
      ,to_char(max(FIRST_TIME),'dd.mm.yyyy hh24:mi') as last_first_time	  
	  ,round(max(BYTES)/1024/1024)||' MB' as maxsize
 from GV$FLASHBACK_DATABASE_LOGFILE
group by inst_id
/

ttitle  "Report Flashback Logs Buffer"  SKIP 2 -

column  name format A40

select * from v$sgastat where name like 'flashback%';

ttitle off