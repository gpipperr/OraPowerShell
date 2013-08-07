--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   overview over the datafiles of the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 300 recsep OFF

ttitle  "Report Database Files"  SKIP 1 -
       center "Sizes in MB" SKIP 2

COLUMN tablespace_name format a12 heading "Tablespace"
COLUMN df_size format 999999 heading "Size"
COLUMN F_ID format 999
COLUMN FILE_NAME format A40 heading "Filename"
column status format A10
column fragidx format A12 heading "Fragmen. Index"

select FILE_ID as F_ID
      ,round((BYTES / 1024 / 1024)) as df_size
      ,TABLESPACE_NAME
      ,FILE_NAME
      ,ONLINE_STATUS as status
  from dba_data_files
 order by TABLESPACE_NAME
         ,FILE_NAME 
/

ttitle  "Report Temp Files"  SKIP 2

select FILE_ID as F_ID
      ,round((BYTES / 1024 / 1024)) as df_size
      ,TABLESPACE_NAME
      ,FILE_NAME
      ,STATUS as status
  from dba_temp_files
 order by TABLESPACE_NAME
         ,FILE_NAME
/

ttitle  "Usage of the datafiles"  SKIP 2

select d.file_name "FILE_NAME"
       ,ROUND(max(d.BYTES) / 1024 / 1024, 2) "total MB"
       ,DECODE(sum(f.BYTES), null, 0, ROUND(sum(f.BYTES) / 1024 / 1024, 2)) "Free MB"
       ,DECODE(sum(f.BYTES), null, 0, ROUND((max(d.BYTES) / 1024 / 1024) - (sum(f.BYTES) / 1024 / 1024), 2)) "Used MB"
       --,         ROUND (MAX (d.BYTES) / 1024, 2) "total KB"
       --,         DECODE (SUM (f.BYTES),
       --                NULL, 0,
       --                 ROUND (SUM (f.BYTES) / 1024, 2)
       --                ) "Free KB"
       --,      DECODE (SUM (f.BYTES),
       --                 NULL, 0,
       --                 ROUND ((MAX (d.BYTES) / 1024) - (SUM (f.BYTES) / 1024), 2)
       --                ) "Used KB"
       ,to_char(ROUND(SQRT(max(f.blocks) / sum(f.blocks)) * (100 / SQRT(SQRT(count(f.blocks)))), 2), '999D00') as fragidx
  from dba_free_space f
      ,dba_data_files d
 where f.tablespace_name(+) = d.tablespace_name
   and f.file_id(+) = d.file_id
 group by d.file_name 
 /

ttitle off
