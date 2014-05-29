	--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   search the table in the database
-- Parameter 1: Name of the sequence
--
-- Must be run with dba privileges
-- 
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
set verify  off
set linesize 120 pagesize 4000 recsep OFF

define SEQ_NAME = '&1' 

prompt
prompt Parameter 1 = SEQ Name          => &&SEQ_NAME.
prompt

column SEQUENCE_OWNER format a14  heading "Qwner" 
column SEQUENCE_NAME  format a20  heading "Sequence|Name"
column CACHE_SIZE     format 9999 heading "Cache|Size"
column INCREMENT_BY   format 999  heading "Inc|val"
column MIN_VALUE  format 999  heading "Min|val"
column MAX_VALUE  format 999  heading "Max|val"
column CYCLE_FLAG format a3 heading "CYC|LE"
column ORDER_FLAG format a3 heading "ORD|ER"
column LAST_NUMBER  format 999G999G999G999  heading "Last|number"

 select SEQUENCE_OWNER
		, SEQUENCE_NAME
		, MIN_VALUE
		, to_char(MAX_VALUE,'09D99EEEE') as MAX_VALUE
		, INCREMENT_BY
		, CYCLE_FLAG
		, ORDER_FLAG
		, CACHE_SIZE
		, LAST_NUMBER
 from dba_sequences 
where upper(SEQUENCE_NAME) like upper('%&&SEQ_NAME.%')
/
 