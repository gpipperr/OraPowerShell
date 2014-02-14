--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the usage of the temp tablepace
-- Date:   02.2014
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

--http://gavinsoorma.com/2009/06/temp-tablespace-usage/
--
--

SET linesize 130 pagesize 300 recsep OFF

column inst_id    format 99     heading "Inst|ID"
column username   format a8     heading "DB User|name"
column sid        format 9999   heading "SID"
column spid       format a8     heading "sPID"
column serial#    format 99999  heading "Serial"
column program    format a19    heading "Remote|program"
column module     format a19    heading "Remote|module"
column tablespace format a10    heading "Table|space"
column osuser     format a12    heading "OS|User"
column mb_used 	format 99999  heading "In USE|MB"
column statements format 9999   heading "Segments"

select  ses.inst_id
		, ses.sid
		, ses.serial# 
      , ses.username
      , ses.osuser
      , to_char(pro.spid) as spid
      , sum(sou.blocks) * tbs.block_size / 1024 / 1024 mb_used
      , sou.tablespace
      , count(*) statements
		, ses.module
      , pro.program
  from  gv$sort_usage    sou
      , gv$session       ses
      , dba_tablespaces  tbs
      , gv$process       pro
 where sou.session_addr = ses.saddr
   and ses.paddr = pro.addr
   and sou.tablespace = tbs.tablespace_name
	and pro.inst_id=sou.inst_id
	and sou.inst_id=ses.inst_id
 group by ses.inst_id
			, ses.sid
         ,ses.serial#
         ,ses.username
         ,ses.osuser
         ,pro.spid
         ,ses.module
         ,pro.program
         ,tbs.block_size
         ,sou.tablespace
 order by ses.inst_id 
/ 

--select s.sid || ',' || s.serial# sid_serial, s.username, s.osuser, p.spid, s.module,
--p.program, sum (t.blocks) * tbs.block_size / 1024 / 1024 mb_used, t.tablespace,
--count(*) statements
--from v$sort_usage t, v$session s, dba_tablespaces tbs, v$process p
--where t.session_addr = s.saddr
--and s.paddr = p.addr
--and t.tablespace = tbs.tablespace_name
--group by s.sid, s.serial#, s.username, s.osuser, p.spid, s.module,
--p.program, tbs.block_size, t.tablespace
--order by sid_serial
--/


select TABLESPACE_NAME
	  , round(TABLESPACE_SIZE/1024/1024,3) as TABLESPACE_SIZE_MB
	  , round(ALLOCATED_SPACE/1024/1024,3) as ALLOCATED_SPACE_MB
	  , round(FREE_SPACE/1024/1024,3)      as FREE_SPACE_MB
 from DBA_TEMP_FREE_SPACE
/

select  bytes
      , MAXBYTES
      , status
      , s.AUTOEXTENSIBLE
      , INCREMENT_BY
		, FILE_ID
  from dba_temp_files s 
/
       
select 'alter database tempfile ''' || s.file_name || ''' resize '||'&TEMP_NEW_SIZE'||';' as command ,FILE_ID
  from dba_temp_files s 
/



