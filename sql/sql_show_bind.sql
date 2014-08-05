-- traditional http://tech.e2sn.com/oracle/troubleshooting/how-to-read-errorstack-output
-- http://tech.e2sn.com/oracle/troubleshooting/oracle-s-real-time-sql-monitoring-feature-v-sql_monitor
-- http://tech.e2sn.com/oracle/troubleshooting/oracle-s-real-time-sql-monitoring-feature-v-sql_monitor

-- only uses if you have  a licence!!
-- show parameter control_management_pack_access
-- check also parameter _sqlmon_binds_xml_format


define SQL_ID='&1'

prompt
prompt Parameter 1 = SQL ID     => &&SQL_ID.
prompt

set pagesize 100
set linesize 130

column session_info format a30         heading "Session|Info" 
column inst_id      format 99          heading "In|Id"
column program      format a16         heading "Remote|program"
column module       format a16         heading "Remote|module"
column action       format a16         heading "Remote|action"
column client_info  format a10         heading "Client|info" FOLD_AFTER 
column client_identifier  format a10   heading "Client|Ident"
column sql_id             format a14   heading "SQL|id"
column bind_var           format a140  heading "Bind XML" WORD_WRAPPED  FOLD_BEFORE FOLD_AFTER 

select inst_id 
	  , username||'(sid:'||sid||')' as session_info	       
     , program
	  , module
	  , action
	  , client_identifier
	  , client_info
	  , replace(replace(to_char(binds_xml),'<',chr(10)||'<'),'>','>'||chr(10)) as bind_var 
     -- proleme Error LPX-00216: invalid character 1 (0x1) bei speziellen Werten in den Bind Variablen	 
	  --, XMLQuery( 'for $i in /binds return $i/bind'  PASSING BY VALUE  XMLType(binds_xml)	RETURNING CONTENT	) as pure_bind
 from gv$sql_monitor 
where sql_id = '&&SQL_ID.'
/

/*

http://dioncho.wordpress.com/2009/05/07/tracking-the-bind-value/
http://docs.oracle.com/cd/B19306_01/server.102/b14237/dynviews_2114.htm

aus AWR
select sql_id,name, position, value_string
    from   (select sql_id,bind_data
            from   dba_hist_sqlstat
            where  bind_data is not null
            and    rownum <= 1) x
        table(dbms_sqltune.extract_binds(x.bind_data)) xx;
*/  


/*
--------------------------------------------
KEY
STATUS
USER#
USERNAME
MODULE
ACTION
SERVICE_NAME
CLIENT_IDENTIFIER
CLIENT_INFO
PROGRAM
PLSQL_ENTRY_OBJECT_ID
PLSQL_ENTRY_SUBPROGRAM_ID
PLSQL_OBJECT_ID
PLSQL_SUBPROGRAM_ID
FIRST_REFRESH_TIME
LAST_REFRESH_TIME
REFRESH_COUNT
SID
PROCESS_NAME
SQL_ID
SQL_TEXT
IS_FULL_SQLTEXT
SQL_EXEC_START
SQL_EXEC_ID
SQL_PLAN_HASH_VALUE
EXACT_MATCHING_SIGNATURE
FORCE_MATCHING_SIGNATURE
SQL_CHILD_ADDRESS
SESSION_SERIAL#
PX_IS_CROSS_INSTANCE
PX_MAXDOP
PX_MAXDOP_INSTANCES
PX_SERVERS_REQUESTED
PX_SERVERS_ALLOCATED
PX_SERVER#
PX_SERVER_GROUP
PX_SERVER_SET
PX_QCINST_ID
PX_QCSID
ERROR_NUMBER
ERROR_FACILITY
ERROR_MESSAGE
BINDS_XML
OTHER_XML
ELAPSED_TIME
QUEUING_TIME
CPU_TIME
FETCHES
BUFFER_GETS
DISK_READS
DIRECT_WRITES
IO_INTERCONNECT_BYTES
PHYSICAL_READ_REQUESTS
PHYSICAL_READ_BYTES
PHYSICAL_WRITE_REQUESTS
PHYSICAL_WRITE_BYTES
APPLICATION_WAIT_TIME
CONCURRENCY_WAIT_TIME
CLUSTER_WAIT_TIME
USER_IO_WAIT_TIME
PLSQL_EXEC_TIME
JAVA_EXEC_TIME
*/


/*

-- over gv$sql_bind_capture this is not working
-- 
select  sb.value_string
     ,  ss.username
     ,  ss.sid||','||ss.serial#||',@'||ss.inst_id
     ,  sb.sql_id
  from --gv$sql_bind_capture sb      
     , DBA_HIST_SQLBIND sb
     , gv$SQLAREA sa
     , gv$session ss
 where sa.inst_id=sb.inst_id   
   and ss.inst_id=sb.inst_id
      
   and ss.SQL_HASH_VALUE = sb.HASH_VALUE
   and ss.SQL_ADDRESS    = sb.ADDRESS
   
   and ss.SQL_HASH_VALUE = sa.HASH_VALUE
   and ss.SQL_ADDRESS    = sa.ADDRESS
   
   and sb.sql_id = '&&sql_id.'
order by ss.username
       , sb.sql_id   
*/	 