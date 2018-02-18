spool ${BACKUP_DEST}/${ORACLE_DBNAME}/dbinfo_${ORACLE_SID}_${DAY_OF_WEEK}.log
set pagesize 300
set linesize 300

define dnum = "format 999G999G999G999G999D99"
define lnum = "format 9G999G999"
define num  = "format 99G999"
define snum = "format 9G999"

column total_mb &&lnum
column group_number format 99  heading "Group Nr."
column inst_id format 99  heading "Inst"
column status  format A6
column state  format A6
column type  format A6
column name  format A12
column free &&lnum
column used &&lnum

column writes &&dnum
column reads &&dnum
column read_errs &&snum   heading "R Er."
column write_errs &&snum  heading "W Er."
column r_tim &&dnum  heading "R Tim."
column w_tim &&dnum heading "W Tim."
column bytes_read &&dnum
column bytes_written &&dnum
column INSTANCE_NAME format A10

column name format a60
column parameter format a40
column value format a30
column property_value format a30
column property_name format a30
column tablespace_name format a20
column FLASHBACK_ON format a40
column LOG_MODE format a20

ttitle  "---------Version--------"  skip 2
select * from v$version;


---- ASM Status ----------------------
ttitle left  "ASM Disk Status and Size" skip 2

select group_number
 , name	 
 ,state
 ,type
 ,total_mb
 ,usable_file_mb as free
 ,total_mb-usable_file_mb as used
from v$asm_diskgroup
/

 
ttitle left  "ASM User" skip 2

column status  format A10
select  inst_id 
  , GROUP_NUMBER
  , INSTANCE_NAME
  , STATUS 
  from gv$ASM_CLIENT 
  order by inst_id,GROUP_NUMBER
/


ttitle left "ASM Disks"

column diskpath format A15
column name format A12

select name
  , path as diskpath
  , TOTAL_MB
  , FREE_MB 
  , total_mb-free_mb as used
from v$asm_disk
/

ttitle left "ASM Disk Extend distribution"

select count(PXN_KFFXP) as Count_Extents
  ,DISK_KFFXP as disk
  ,GROUP_KFFXP as diskgroup 
from X$KFFXP group by DISK_KFFXP,GROUP_KFFXP
/



ttitle left  "ASM Disk Performance" skip 2
column name  format A7
select  inst_id
      , group_number
      , replace(name,'_0000','') as name
      , reads
      , writes
      , read_errs
      , write_errs
      , read_time as r_tim
      , write_time as w_tim
      , bytes_read
      , bytes_written 
 from gv$asm_disk_stat 
where group_number > 0 
order by inst_id,group_number, disk_number;

prompt
prompt R Er.  :  read Errors
prompt w Er.  :  write Errors
prompt r_tim  :  read time in cs
prompt w_tim  :  write time in cs
prompt

ttitle left  "ASM Files on Storage" skip 2

column name format a30
select  f.group_number
      , f.FILE_NUMBER
      , f.BYTES,a.name
from v$asm_file f
   , v$asm_alias a
where f.file_number  = a.file_number
  and f.group_number = a.group_number
order by f.file_number
/ 

ttitle off

spool off
exit;
