--==============================================================================
-- Desc:   show the errors in the database
-- Must be run with dba privileges
-- 
--==============================================================================


set verify  off
set linesize 130 pagesize 4000 recsep OFF
set trimspool on

/*
desc dba_errors;
 Name                                                                    Null?    Type
 ----------------------------------------------------------------------- -------- ---------------------------
 OWNER                                                                   NOT NULL VARCHAR2(30)
 NAME                                                                    NOT NULL VARCHAR2(30)
 TYPE                                                                             VARCHAR2(12)
 SEQUENCE                                                                NOT NULL NUMBER
 LINE                                                                    NOT NULL NUMBER
 POSITION                                                                NOT NULL NUMBER
 TEXT                                                                    NOT NULL VARCHAR2(4000)
 ATTRIBUTE                                                                        VARCHAR2(9)
 MESSAGE_NUMBER                                                                   NUMBER
 
*/

column owner format a30 heading "Owner"
column name  format a30 heading "Object|Name"
column type  format a20 heading "Object|Type"
column line  format 9G999 heading "Line|No."
column text  format a100 heading "Error Message" fold_before WORD_WRAPPED NEWLINE

select owner
     , name
	  , type
	  , line
	  , text 
from dba_errors
order by owner
        , name
		  , line
/
