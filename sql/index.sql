--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   show information about a index
-- Parameter 1: Owner of the index
-- Parameter 2: Index Name
--
-- Must be run with dba privileges
-- 
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

set verify  off
set linesize 120 pagesize 4000 recsep OFF

define OWNER = '&1' 
define INDEX_NAME = '&2' 

prompt
prompt Parameter 1 = Owner       => &&OWNER.
prompt Parameter 2 = Index Name  => &&INDEX_NAME.
prompt

ttitle center "Index &&OWNER..&&INDEX_NAME.  Columns" SKIP 2

SET linesize 130 pagesize 2000 recsep OFF

column  index_owner format a10
column  index_name  format a25
column  table_name  format a25
column  column_name format a20
column  pos1        format a15 heading "c1"
column  pos2        format a10 heading "c2" 
column  pos3        format a8  heading "c3"
column  pos4        format a4  heading "c4"
column  pos5        format a4  heading "c5"
column  pos6        format a4  heading "c6"
column  pos7        format a3  heading "c7"
column  pos8        format a3  heading "c8"
column  pos9        format a2  heading "c9"
      
select *
  from (select *
          from (select index_owner
                      ,table_name
                      ,index_name
                      ,column_name
                      ,column_position
                  from dba_ind_columns
                 where index_owner like '&&OWNER.%'
				  and  index_name like upper('%&&INDEX_NAME.%')
                 order by index_owner
                         ,table_name) pivot(min(column_name) for column_position in('1' as pos1, '2' as pos2,
                                                                                    '3' as pos3, '4' as pos4, '5' as pos5,
                                                                                    '6' as pos6, '7' as pos7, '8' as pos8,
                                                                                    '9' as pos9)))
/

--ttitle center "Index &&OWNER..&&INDEX_NAME.  Partitions" SKIP 2


ttitle off
