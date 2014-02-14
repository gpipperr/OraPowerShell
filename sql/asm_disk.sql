--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script ASM Disk Overview
-- Date:   2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET pagesize 300
SET linesize 250

ttitle left  "ASM Disk Status and Size" skip 2

define dnum = "format 999G999G999G999D99"
define lnum = "format 9G999G999"
define num  = "format 99G999"
define snum  = "format 9G999"

column total_mb &&lnum
column group_number format 99  heading "Grp Nr."
column inst_id format 99  heading "Inst"
column status  format A6
column state  format A7
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

select  group_number
      , name
      , state
      , type
      , total_mb  Brutto
		, decode(type,'NORMAL',total_mb/2,total_mb) Netto
      , usable_file_mb as free_netto
		, round(usable_file_mb/(decode(type,'NORMAL',total_mb/2,total_mb)/100),2) as free_percent
    --, total_mb - usable_file_mb as used
  from v$asm_diskgroup
order by name  
/

ttitle off




