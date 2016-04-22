--==============================================================================
-- GPI - Gunther Pippèrr 
-- Desc:   show asm balance
-- Date:   November 2013
--==============================================================================
set linesize 130 pagesize 300 recsep off


define GROUP_NUMBER = &1 

prompt
prompt Parameter 1 = Group Number       => &&GROUP_NUMBER.
prompt

define dnum = "format 999G999G999G999D99"
define lnum = "format 9G999G999"
define num  = "format 99G999"
define snum  = "format 9G999"

column bytes format &&dnum heading "Bytes|total"  
column group_number format 999 heading "Grp|Nr"
column name format a20 heading "Disk|Name"
column doublecount  format 99 "File|Count"

ttitle left  "ASM Disk Status and Size" skip 2

select a.group_number
      ,a.name
      ,b.bytes
      ,count(*) over(partition by a.group_number, a.file_number, a.file_incarnation) doublecount
  from v$asm_alias a
      ,v$asm_file  b
 where a.group_number = b.group_number
   and b.group_number=&&GROUP_NUMBER.
   and a.file_number = b.file_number
   and a.file_incarnation = b.incarnation
/

ttitle off
