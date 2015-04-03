--==============================================================================
--
-- Desc:   Get the statistic settings of the table
-- Parameter 1: Name of the User
-- in work
-- Analyse the partitions of the table of a user
--
-- Must be run with dba privileges
-- 
--
--==============================================================================
set linesize 130 pagesize 300 recsep off

define USER_NAME  = &1

prompt
prompt Parameter 1 = Owner Name => &&USER_NAME.
prompt




column owner          format a12 heading "Owner"
column name           format a30 heading "Name" 
column object_type    format a6 heading "Object|Type"
column column_name    format a20 heading "Column|Name"
column column_position format 99 heading "Pos"

-- dba_partition_columns

select  c.owner
      , c.name
	   , c.object_type
	   , c.column_name
	   , c.column_position 
  from  dba_part_key_columns c      
where c.owner like upper('&&USER_NAME.')
order by c.name,c.column_position
/