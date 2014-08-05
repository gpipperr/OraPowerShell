
SET pagesize 500
SET linesize 250

column LOG_OWNER             format a10
column MASTER                format a22
column LOG_TABLE             format a26
column LOG_TRIGGER           format a10
column ROWIDS                format a3
column PRIMARY_KEY           format a3
column OBJECT_ID             format a3
column FILTER_COLUMNS        format a3
column SEQUENCE              format a3
column INCLUDE_NEW_VALUES    format a3
column PURGE_ASYNCHRONOUS    format a3
column PURGE_DEFERRED        format a3
column PURGE_START           format a18
column PURGE_INTERVAL        format a20
column LAST_PURGE_DATE       format a18
column LAST_PURGE_STATUS     format 99999 heading "Purge|Status"
column NUM_ROWS_PURGED       format 999G999 heading "Num|Rows P"
column COMMIT_SCN_BASED      format a3
column SIZE_MB               format 999G990D99

COMPUTE SUM OF NUM_ROWS_PURGED ON LOG_OWNER;
COMPUTE SUM OF SIZE_MB ON LOG_OWNER;
BREAK ON LOG_OWNER;

select ml.LOG_OWNER
     , ml.MASTER
     , ml.LOG_TABLE
     --, ml.LOG_TRIGGER
    -- , ml.ROWIDS
    -- , ml.PRIMARY_KEY
     --, ml.OBJECT_ID
   --  , ml.FILTER_COLUMNS
   --  , ml.SEQUENCE
   --  , ml.INCLUDE_NEW_VALUES
   --  , ml.PURGE_ASYNCHRONOUS
   --  , ml.PURGE_DEFERRED
    -- , ml.PURGE_START
    -- , ml.PURGE_INTERVAL
     , to_char(ml.LAST_PURGE_DATE,'dd.mm.yyyy hh24:mi') as LAST_PURGE_DATE
     , ml.LAST_PURGE_STATUS
     , ml.NUM_ROWS_PURGED
   --  , ml.COMMIT_SCN_BASED
	  , round((ds.bytes/1024/1024),2) as SIZE_MB
from  DBA_MVIEW_LOGS ml
    , dba_segments ds
where ds.OWNER(+)        = ml.LOG_OWNER
  and ds.SEGMENT_NAME(+) = ml.LOG_TABLE
order by ml.LOG_OWNER, ml.LOG_TABLE
/


-- LOG_OWNER	VARCHAR2(30)	 	Owner of the materialized view log
-- MASTER	VARCHAR2(30)	 		Name of the master table or master materialized view whose changes are logged
-- LOG_TABLE	VARCHAR2(30)	 	Name of the table where the changes to the master table or master materialized view are logged
-- LOG_TRIGGER	VARCHAR2(30)	 	Obsolete with Oracle8i and later. Set to NULL. Formerly, this parameter was an after-row trigger on the master which inserted rows into the log.
-- ROWIDS	VARCHAR2(3)	 			Indicates whether rowid information is recorded (YES) or not (NO)
-- PRIMARY_KEY	VARCHAR2(3)	 		Indicates whether primary key information is recorded (YES) or not (NO)
-- OBJECT_ID	VARCHAR2(3)	 		Indicates whether object identifier information in an object table is recorded (YES) or not (NO)
-- FILTER_COLUMNS	VARCHAR2(3)	 	Indicates whether filter column information is recorded (YES) or not (NO)
-- SEQUENCE	VARCHAR2(3)	 			Indicates whether the sequence value, which provides additional ordering information, is recorded (YES) or not (NO)
-- INCLUDE_NEW_VALUES	VARCHAR2(3)	 	Indicates whether both old and new values are recorded (YES) or old values are recorded but new values are not recorded (NO)
-- PURGE_ASYNCHRONOUS	VARCHAR2(3)	 	Indicates whether the materialized view log is purged asynchronously (YES) or not (NO)
-- PURGE_DEFERRED	VARCHAR2(3)	 			Indicates whether the materialized view log is purged in a deferred manner (YES) or not (NO)
-- PURGE_START	DATE	 						For deferred purge, the purge start date
-- PURGE_INTERVAL	VARCHAR2(200)	 		For deferred purge, the purge interval
-- LAST_PURGE_DATE	DATE	 				Date of the last purge
-- LAST_PURGE_STATUS	NUMBER	 			Status of the last purge (error code or 0 for success)
-- NUM_ROWS_PURGED	NUMBER	 			Number of rows purged in the last purge
-- COMMIT_SCN_BASED	VARCHAR2(3)	 		Indicates whether the materialized view log is commit SCN-based (YES) or not (NO)


-- Native:
-- select log, sysdate, youngest, youngest+1/86400,  oldest, oldest_pk, oldest_oid, oldest_new, oldest_seq,  oscn, oscn_pk, oscn_oid, oscn_new, oscn_seq, flag, purge_job  from sys.mlog$
--