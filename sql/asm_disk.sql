--==============================================================================
-- Author: Gunther Pippèrr
-- Desc:   SQL Script ASM Disk Overview
-- Date:   2012
--==============================================================================
-- http://jarneil.wordpress.com/2008/04/10/keep-disks-in-your-diskgroup-the-same-size/
-- http://docs.oracle.com/cd/E24628_01/em.121/e25160/asm_cluster.htm#EMDBM10000
--==============================================================================

set linesize 130 pagesize 300 recsep off

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


ttitle left  "Check ASM Disk Size and Usage over all groups" skip 2

column Brutto   format 999G999G999 heading "Size per|Disk MB" 
column d_cnt    format 999         heading "Count|Disk" 
column max_used format 999G999G999 heading "Max per Disk|Used MB"
column min_used format 999G999G999 heading "Min per Disk|Used MB"
column oem_metric_imblance format 90D00 heading "OEM Disk|Imbalance"

select  g.group_number
      , g.name     
      , d.total_mb Brutto
      , max(d.total_mb-d.free_mb + (128*g.allocation_unit_size/1048576)) max_used
      , min(d.total_mb-d.free_mb + (128*g.allocation_unit_size/1048576)) min_used    
		, count(d.DISK_NUMBER ) as d_cnt		
		, round(100*(max((d.total_mb-d.free_mb + (128*g.allocation_unit_size/1048576))/(d.total_mb + (128*g.allocation_unit_size/1048576)))-min((d.total_mb-d.free_mb + (128*g.allocation_unit_size/1048576))/(d.total_mb + (128*g.allocation_unit_size/1048576))))/max((d.total_mb-d.free_mb + (128*g.allocation_unit_size/1048576))/(d.total_mb + (128*g.allocation_unit_size/1048576))),2) as oem_metric_imblance
from     v$asm_disk_stat d
        ,v$asm_diskgroup_stat g
        ,v$asm_operation op		 
where  d.group_number = g.group_number 
  and  g.group_number = op.group_number(+) 
  and  d.group_number <> 0 
  and  d.state = 'NORMAL' 
  and  d.mount_status = 'CACHED'  
group by g.group_number,g.name,d.total_mb 
order by g.name,d.total_mb 
/

prompt ...
prompt ... if Max per Disk|Used MB and Min per Disk|Used MB are very different you may be need a "alter diskgroup xxxx rebalance power 5"
prompt ...

ttitle off






