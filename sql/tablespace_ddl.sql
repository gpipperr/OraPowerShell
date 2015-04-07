--==============================================================================
-- GPI - Gunther Pippèrr
-- Desc: get the ddl of a tablespace, show default storage options!  
--       Parameter name of the tablespace
--==============================================================================
set verify  off
set linesize 130 pagesize 4000 recsep off

define TABLESPACE_NAME = '&1' 

prompt
prompt Parameter 1 = Tablespace Name => &&TABLESPACE_NAME.
prompt

set long 1000000;

column tab_ddl format a100 heading "Tablespace DDL" WORD_WRAPPED

select dbms_metadata.get_ddl('TABLESPACE','&&TABLESPACE_NAME.')  as tab_ddl 
  from dual
/
