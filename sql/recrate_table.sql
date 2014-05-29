
---------------------------------------
set pagesize 1000
set linesize 130
set verify off
set timing on
set time on

---------------------------------------
-- Parameter
define USER_NAME   ='LMS_PL'
define TABLE_NAME  ='CDS_POSTAL_ADDRESS'
define ORDER_BY_COL='CUSTOMER_ID'
define TABLE_SPACE ='tablespace TS_DATA_COMP'
define SET_PARALLEL=8




alter session force parallel dml parallel   &&SET_PARALLEL.;
alter session force parallel query parallel &&SET_PARALLEL.;


create table &&USER_NAME..&&TABLE_NAME._SAVE
	&&TABLE_SPACE 
	COMPRESS FOR ALL OPERATIONS 
    as select * 
	      from &&USER_NAME..&&TABLE_NAME. 
	     order by &&ORDER_BY_COL
/


select *
  from dba_tables t, dba_segments s
 where t.owner = 'LMS_PL' 
   and t.table_name like ('.&&TABLE_NAME.%')
   and s.owner = t.owner
   and t.TABLE_NAME = s.segment_name
/	