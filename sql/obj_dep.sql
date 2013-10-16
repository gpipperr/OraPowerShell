--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script to check the size of a table
-- Doku:   http://www.pipperr.de/dokuwiki/doku.php?id=dba:sql_groesse_tabelle
-- Date:   08.2013
-- Site:   http://orapowershell.codeplex.com

-- http://www.dba-oracle.com/t_tracking_table_constraint_dependencies.htm

--==============================================================================

SET pagesize 300
SET linesize 250
SET VERIFY OFF

define OWNER    = '&1' 
define TAB_NAME = '&2' 

prompt
prompt Parameter 1 = Owner Name => &&OWNER.
prompt Parameter 2 = Tab Name   => &&TAB_NAME.
prompt

ttitle left  "Dependency Usage of the table &OWNER..&TAB_NAME." skip 2


column clevel    heading "Object|level"         format a16
column obj_name  heading "Object|name"          format a40
column ref_obj   heading "Ref|object"           format a40

select  lpad(' ', 2 * (level - 1)) || to_char(level, '999') as clevel
      , owner || '.' || name || ' (' || type || ')' as obj_name
      , referenced_owner || '.' || referenced_name || ' (' || referenced_type || ')' as ref_obj
  from all_dependencies
 start with owner = upper('&OWNER')
        and name = upper('&TAB_NAME')
connect by prior referenced_owner = owner
       and prior referenced_name = name
       and prior referenced_type = type
--       and type = 'TABLE'
/	   

prompt
prompt ... alternativ use the utldtree utility $ORACLE_HOME/rdbms/admin/utldtree.sql 
prompt ... to create the helper function and call =>  deptree_fill('object_type', 'object_owner', 'object_name'); |  select * from ideptree;
prompt
