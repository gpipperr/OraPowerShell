SET linesize 1000 pagesize 800 recsep OFF

set serveroutput on

-------------------
-- create spool name
col SPOOL_NAME_COL new_val SPOOL_NAME
 
SELECT replace(ora_database_name||'_'||SYS_CONTEXT('USERENV','HOST')||'_'||to_char(sysdate,'dd_mm_yyyy_hh24_mi')||'_streams_sql_.sql','\','_') 
--' resolve syntax highlight bug FROM my editer .-(
  AS SPOOL_NAME_COL
FROM dual
/

alter session set NLS_TERRITORY=AMERICA;;
alter session set NLS_LANGUAGE=AMERICAN;;
alter session set NLS_NUMERIC_CHARACTERS='.,';;



spool &&SPOOL_NAME

prompt 
prompt spool recreate_&&SPOOL_NAME.log
prompt
prompt
prompt prompt  ============ Start ================
prompt select to_char(sysdate,'dd.mm.yyyy hh24:mi') as start_date from dual
prompt /
prompt prompt  ===================================
prompt 
prompt alter session set NLS_TERRITORY=AMERICA;;
prompt alter session set NLS_LANGUAGE=AMERICAN;;
prompt alter session set NLS_NUMERIC_CHARACTERS='.,';;
prompt  

prompt set heading   on
prompt set echo      on
prompt set feedback  on
prompt set define   off

declare 
 CURSOR c IS
    SELECT LOCAL_TRANSACTION_ID,
           SOURCE_DATABASE,
           MESSAGE_NUMBER,
           MESSAGE_COUNT,
           ERROR_NUMBER,
           ERROR_MESSAGE
      FROM DBA_APPLY_ERROR
      ORDER BY LOCAL_TRANSACTION_ID,MESSAGE_NUMBER,SOURCE_DATABASE, SOURCE_COMMIT_SCN;
		
  i      NUMBER;
  txnid  VARCHAR2(30);
  source VARCHAR2(128);
  msgno  NUMBER;
  msgcnt NUMBER;
  errnum NUMBER := 0;
  errno  NUMBER;
  errmsg VARCHAR2(255);
  lcr    SYS.AnyData;
  r      NUMBER;
  rowlcr          SYS.LCR$_ROW_RECORD;
  v_sqltext      clob:=' ';
  e_lcr    SYS.AnyData;
  res       NUMBER;
BEGIN
  
  FOR r IN c LOOP
    errnum := errnum + 1;
    msgcnt := r.MESSAGE_COUNT;
    txnid  := r.LOCAL_TRANSACTION_ID;
    source := r.SOURCE_DATABASE;
    msgno  := r.MESSAGE_NUMBER;
    errno  := r.ERROR_NUMBER;
    errmsg := r.ERROR_MESSAGE;
	 
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('-- ERROR #              : ' || errnum);
    DBMS_OUTPUT.PUT_LINE('-- Local Transaction ID : ' || txnid);
    DBMS_OUTPUT.PUT_LINE('-- Source Database      : ' || source);
    DBMS_OUTPUT.PUT_LINE('-- Error in Message     : ' || msgno );
    DBMS_OUTPUT.PUT_LINE('-- Error Number         : ' ||errno);
    DBMS_OUTPUT.PUT_LINE('-- Message Text         : ' );
	 DBMS_OUTPUT.PUT_LINE('/*');
	 DBMS_OUTPUT.PUT_LINE(errmsg);
	 DBMS_OUTPUT.PUT_LINE('*/');	 
	 DBMS_OUTPUT.PUT_LINE('-- Message Count        : ' ||msgcnt);
	 DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
	 DBMS_OUTPUT.PUT_LINE(' ');
	 
    FOR i IN 1..msgcnt LOOP
	     -- reinitialise all variables! 
        v_sqltext:=' ';
		  rowlcr:=null;
		  res:=null;
		  e_lcr:=null;
		  
		  --- read LCR
        begin
		   e_lcr := DBMS_APPLY_ADM.GET_ERROR_MESSAGE(i, txnid); 
		  		  
		   res := e_lcr.GETOBJECT(rowlcr);

		   rowlcr.get_row_text(v_sqltext);
		  
		  exception 
		   when others then 
			 DBMS_OUTPUT.PUT_LINE('-- Error: '||SQLERRM);
		  end;
		  
		  DBMS_OUTPUT.PUT_LINE('-- Message id :' ||i);
		  DBMS_OUTPUT.PUT_LINE('-- SQL Command:');    
		  DBMS_OUTPUT.PUT_LINE(substr(v_sqltext,1,32000));
		  DBMS_OUTPUT.PUT_LINE('/');
		  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
		  
		   -- Falls im Spool Fehler auftauchen, direkt ausführen!
		   --
		   --begin
		   --	 execute immediate v_sqltext;		  
		   --	 DBMS_OUTPUT.PUT_LINE('----------sucessfully execute sql from message:'||i||'for '|| %SQLCOUNT ||' records');
		   -- exception 
		   -- when others then 
			-- DBMS_OUTPUT.PUT_LINE('-- Error execute the SQL: '||v_sqltext);
			-- DBMS_OUTPUT.PUT_LINE('-- Error execute the SQL: '||SQLERRM);
		   -- end;		  
			
			
    END LOOP;		  
  END LOOP;
END;
/

prompt 
prompt prompt  ============ Finish ================
prompt select to_char(sysdate,'dd.mm.yyyy hh24:mi') as finish_date from dual
prompt /
prompt prompt  ===================================
prompt 
prompt prompt to check the log see recreate_&&SPOOL_NAME.log
prompt prompt !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
prompt prompt dont forget the commit if all is ok!
prompt prompt !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

prompt set heading  on
prompt set feedback off
prompt set define on

spool off 

prompt .....
prompt to start he recreate scripts use the script:  &&SPOOL_NAME
prompt .....

