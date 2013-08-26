--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- tab_stat.sql
-- Get the statistic settings of the table
-- Parameter 1: Name of the table
--
-- Must be run with dba privileges
-- 
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
define TABLE_NAME = &1 
define USER_NAME  = &2

set verify off

create or replace function show_rawvalue(p_rawval raw, p_dtype varchar2)
  return varchar2 is
  -- different datatypes
  v_cn  number;
  v_cv  varchar2(32);
  v_cd  date;
  v_cnv nvarchar2(32);
  v_cr  rowid;
  v_cc  char(32);
  v_cbf binary_float;
  v_cbd binary_double;
  -- return value
  v_return varchar2(4000);
begin
    
  CASE p_dtype
    WHEN 'VARCHAR2' THEN
      dbms_stats.convert_raw_value(p_rawval, v_cv);
      v_return := to_char(v_cv);
    WHEN 'DATE' THEN
      dbms_stats.convert_raw_value(p_rawval, v_cd);
      v_return := to_char(v_cd,'DD.MM.YYYY HH24:MI:SS');
    WHEN 'NUMBER' THEN
      dbms_stats.convert_raw_value(p_rawval, v_cn);
      v_return := to_char(v_cn);
    WHEN 'BINARY_FLOAT' then
      dbms_stats.convert_raw_value(p_rawval, v_cbf);
      v_return := to_char(v_cbf);
    WHEN 'BINARY_DOUBLE' then
      dbms_stats.convert_raw_value(p_rawval, v_cbd);
      v_return := to_char(v_cbd);
    WHEN 'NVARCHAR2' then
      dbms_stats.convert_raw_value_nvarchar(p_rawval, v_cnv);
      v_return := to_char(v_cnv);
    WHEN 'ROWID' then
      dbms_stats.convert_raw_value_rowid(p_rawval, v_cr);
      v_return := to_char(v_cr);
    WHEN 'CHAR' then
      dbms_stats.convert_raw_value(p_rawval, v_cc);
      v_return := to_char(v_cc);
    ELSE
      v_return := 'UNKNOWN DATATYPE';
  END CASE;
  
  RETURN v_return;

end;
/


SET linesize 150 pagesize 200 recsep OFF

ttitle "Read Statistic Values for this table &TABLE_NAME." SKIP 2

column table_name  format a15

select  table_name
      , status
	  , to_char(LAST_ANALYZED,'dd.mm.yyyy hh24:mi')
	  , NUM_ROWS
	  , AVG_SPACE
	  , CHAIN_CNT
	  , AVG_ROW_LEN
 from dba_tables
where table_name like '&TABLE_NAME.%'
  and  owner      like '&USER_NAME.%'
/

prompt ... to anaylse the space Usage use tab.sql

ttitle center "Read Statistic Values of the columns of this table " SKIP 2


column column_name format a18
column low_value   format a35
column high_value  format a35
column data_type   format a10
column histogram   format a15

set serveroutput on

select  b.table_name
	  ,	b.column_name
  	  , show_rawvalue(a.low_value  , b.data_type)  as low_value
	  ,	show_rawvalue(a.high_value , b.data_type) as high_value
	  , b.data_type
	  , a.histogram 
  from dba_tab_col_statistics a
     , dba_tab_cols b
 where b.table_name like '&TABLE_NAME.%'
   and b.owner      like '&USER_NAME.%'
   and a.table_name   (+) = b.table_name
   and a.owner        (+) = b.owner
   and a.column_name  (+) = b.column_name 
 order by  1,2
/

ttitle left  "Overview histogram statistic usage for this table" skip 2

select  table_name 
      , column_name 
      , count(*) as count_hist_buckets
 from DBA_TAB_HISTOGRAMS 
where table_name like '&TABLE_NAME.%'
 and  owner      like '&USER_NAME.%'
group by table_name ,column_name
order by column_name
/

-- Details Analyse 
-- column endpoint_number format 99999  heading "End|Nr."
-- column endpoint_value   heading "Value"
-- column endpoint_actual_value format a30 heading "Act|Value"
-- 	  
-- 	  
-- select  table_name 
--       , column_name 
--       , endpoint_number
--       , endpoint_value
--       , endpoint_actual_value
--  from DBA_TAB_HISTOGRAMS 
-- where table_name like '&TABLE_NAME.%'
--  and  owner      like '&USER_NAME.%'
-- order by column_name,ENDPOINT_NUMBER
-- /


spool off
ttitle off

drop function show_rawvalue
/