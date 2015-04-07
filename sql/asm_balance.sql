--==============================================================================
-- GPI - Gunther Pippèrr 
-- Desc:   show asm balance
-- Date:   November 2013
--==============================================================================
set linesize 130 pagesize 300 recsep off

select a.group_number
      ,a.name
      ,b.bytes
      ,count(*) over(partition by a.group_number, a.file_number, a.file_incarnation) doublecount
  from v$asm_alias a
      ,v$asm_file  b
 where a.group_number = b.group_number
   and a.file_number = b.file_number
   and a.file_incarnation = b.incarnation
/


