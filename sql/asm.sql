--==============================================================================
-- Author: Gunther Pipp�rr ( http://www.pipperr.de )
-- Desc:   SQL Script ASM Disk Overview
-- Date:   2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET pagesize 300
SET linesize 250

spool asm.log

ttitle left  "ASM Disk Status and Size" skip 2

define dnum = "format 999G999G999G999D99"
define lnum = "format 9G999G999"
define num  = "format 99G999"
define snum  = "format 9G999"

column total_mb &&lnum
column group_number format 99  heading "Grp Nr."
column inst_id format 99  heading "Inst"
column status  format A6
column state  format A6
column type  format A6
column name  format A20
column free &&lnum
column used &&lnum

column writes &&dnum
column reads &&dnum
column read_errs &&snum   heading "R Er."
column write_errs &&snum  heading "W Er."
column r_tim &&dnum  heading "R Tim."
column w_tim &&dnum heading "W Tim."
column bytes_read &&num
column bytes_written &&num
column INSTANCE_NAME format A10

select group_number
      ,name
      ,state
      ,type
      ,total_mb
      ,usable_file_mb as free
      ,total_mb - usable_file_mb as used
  from v$asm_diskgroup
/

prompt ----------------------

ttitle left  "ASM User" skip 2

column status  format A10
select inst_id
      ,GROUP_NUMBER
      ,INSTANCE_NAME
      ,STATUS
  from gv$ASM_CLIENT
 order by inst_id
         ,GROUP_NUMBER
/


ttitle left "ASM Disks"
prompt ----------------------

column diskpath format A15
column name format A12

select GROUP_NUMBER
      ,name
      ,path as diskpath
      ,TOTAL_MB
      ,FREE_MB
      ,total_mb - free_mb as used
  from v$asm_disk
/

ttitle left "ASM Disk Extend distribution"
prompt ----------------------

select count(PXN_KFFXP) as Count_Extents
      ,DISK_KFFXP as disk
      ,GROUP_KFFXP as diskgroup
  from X$KFFXP
 group by DISK_KFFXP
         ,GROUP_KFFXP
/


prompt ----------------------

ttitle left  "ASM Disk Performance" skip 2

column name  format A7
select inst_id
      ,group_number
      ,replace(name, '_0000', '') as name
      ,reads
      ,writes
      ,read_errs
--    , write_errs
--    , bytes_read/read_time 
--    , bytes_written/write_time
--    , bytes_read
--    , bytes_written 
  from gv$asm_disk_stat
 where group_number > 0
 order by inst_id
         ,group_number
         ,disk_number;

--prompt
--prompt R Er.  :  read Errors
--prompt w Er.  :  write Errors
--prompt r_tim  :  read time in cs
--prompt w_tim  :  write time in cs
prompt

/*
ttitle left  "ASM Files on Storage" skip 2

column name format a30
select f.group_number
      ,f.FILE_NUMBER
      ,f.BYTES
      ,a.name
  from v$asm_file  f
      ,v$asm_alias a
 where f.file_number = a.file_number
   and f.group_number = a.group_number
 order by f.file_number
/ 

*/

ttitle off

spool off


