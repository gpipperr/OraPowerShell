----------------------------
----------------------------


-- use the default block size as variable
-- 
col BLOCK_SIZE_COL new_val BLOCK_SIZE

column BLOCK_SIZE_COL format a20 heading "Default DB Blocksize"
  
select value as BLOCK_SIZE_COL
  from v$parameter 
 where name = 'db_block_size'
 /



 
set pages 300 lines 300
set verify off

column tablespace_name     format a25         heading "Tablespace|Name"
column used_space_gb       format 999G990D999 heading "Used Space|GB"
column tablespace_size_gb  format 999G990D999 heading "Max Tablespace|Size GB"
column DF_SIZE_GB          format 999G990D999 heading "Size on| Disk GB"
column used_percent        format 90G99       heading "Used |%"  
column BLOCK_SIZE          format 99G999      heading "TBS BL|Size"  
column DF_Count            format 9G999       heading "Count|DB Files"  

select dt.tablespace_name
 	 ,  round((dm.tablespace_size * dt.BLOCK_SIZE)/1024/1024/1024,3) as tablespace_size_gb     	 
	 ,  round( 
			(case dt.CONTENTS
				when 'TEMPORARY' then
					(select sum(df.BLOCKS)*dt.BLOCK_SIZE from dba_temp_files df where df.TABLESPACE_NAME=dt.tablespace_name)
				else
				(select sum(df.BLOCKS)*dt.BLOCK_SIZE from dba_data_files df where df.TABLESPACE_NAME=dt.tablespace_name)
		   end) /1024/1024/1024,3)  as DF_SIZE_GB
    ,  (case dt.CONTENTS
				when 'TEMPORARY' then
					(select count(*) from dba_temp_files df where df.TABLESPACE_NAME=dt.tablespace_name)
				else
				(select count(*) from dba_data_files df where df.TABLESPACE_NAME=dt.tablespace_name)
		   end)  as DF_Count					
	 ,  round(((dm.used_space * dt.BLOCK_SIZE)/1024/1024/1024),3)      as used_space_gb         		
  	 ,  round(100*dm.used_percent,2) as used_percent
	 ,  dt.BLOCK_SIZE
  from DBA_TABLESPACE_USAGE_METRICS dm
     , dba_tablespaces dt
where dm.tablespace_name=dt.tablespace_name
order by dm.tablespace_name
/


set verify on


