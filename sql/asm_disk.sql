--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script ASM Disk Overview
-- Date:   2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
-- http://jarneil.wordpress.com/2008/04/10/keep-disks-in-your-diskgroup-the-same-size/
-- http://docs.oracle.com/cd/E24628_01/em.121/e25160/asm_cluster.htm#EMDBM10000



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
column state  format A10 heading "State"
column type  format A6  heading "Type"
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
column free_percent format a6 heading "free|%"
column free_netto format 999G999G999 heading "Usable|netto"
column Netto      format 999G999G999 heading "Usable|total"
column Brutto     format 999G999G999 heading "Disk|total"  
column disk_count format 999 heading "Disk|cnt"

select  g.group_number
      , g.name
      , g.state
      , g.type
      , g.total_mb  Brutto
		, decode(g.type,'NORMAL',g.total_mb/2,g.total_mb) Netto
      , g.usable_file_mb as free_netto
		, case when g.state !='DISMOUNTED' then
				to_char(round(g.usable_file_mb/(decode(type,'NORMAL',g.total_mb/2,g.total_mb)/100),2),'00D99')
		   else 'n/a'			
		 end as free_percent
		,(select count(*) from v$asm_disk i where i.group_number=g.group_number) as disk_count
  from v$asm_diskgroup g
order by g.name  
/

ttitle off




