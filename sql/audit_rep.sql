--==============================================================================
--
-- Desc:   HTML Report for the entries in the audit log
-- see :   http://www.pipperr.de/dokuwiki/doku.php?id=dba:index_column_usage
-- Date:   September 2013
--
--==============================================================================

/*
Timeformat differences between audit$ and audit trail!
select 
    ntimestamp#,
    from_tz(ntimestamp#,'UTC') at local,
    from_tz(ntimestamp#,'UTC') at time zone 'Europe/Berlin'
from sys.aud$;

*/

col SPOOL_NAME_COL new_val SPOOL_NAME
 
SELECT replace(ora_database_name||'_'||SYS_CONTEXT('USERENV','HOST')||'_'||to_char(sysdate,'dd_mm_yyyy_hh24_mi')||'_audit_log.html','\','_') 
--' resolve syntax highlight bug FROM my editer .-(
  AS SPOOL_NAME_COL
FROM dual
/

set verify off
SET linesize 250 pagesize 2000 recsep off

spool &&SPOOL_NAME


set markup html on

ttitle left  "Audit Log entries " skip 2

column username    format a10  heading "DB User|name"
column action_name format a25  heading "Action|name"
column first_log   format a25  heading "First|entry"
column last_log    format a25  heading "Last|entry"


select  OS_USERNAME
	, USERNAME
	, USERHOST
	, TERMINAL
    , to_char(TIMESTAMP,'dd.mm.yyyy hh24:mi:ss') as timestamp
    , OWNER
    , OBJ_NAME
 ,ACTION_NAME
 ,NEW_OWNER
 ,NEW_NAME
--,SES_ACTIONS
 ,COMMENT_TEXT
 ,SESSIONID
--,ENTRYID
--,STATEMENTID
--,RETURNCODE
--,PRIV_USED
--,CLIENT_ID
-- ,ECONTEXT_ID
-- ,SESSION_CPU
-- ,EXTENDED_TIMESTAMP
-- ,PROXY_SESSIONID
 --,GLOBAL_UID
 --,INSTANCE_NUMBER
 --,OS_PROCESS
 --,TRANSACTIONID
 --,SCN
-- ,SQL_BIND
 ,SQL_TEXT
-- ,OBJ_EDITION_NAME
 from dba_audit_object
where timestamp between sysdate-21 and sysdate
order by timestamp
/

set markup html off

spool off
ttitle off

-- works only in a ms windows environment
-- auto start of the result in a browser window
host &&SPOOL_NAME
