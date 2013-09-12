--==============================================================================
-- Author: Gunther Pipp�rr ( http://www.pipperr.de )
-- Desc:   nls settings of the Session and the database
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 120

ttitle left  "Session NLS Lang Values" skip 2

select  SYS_CONTEXT('USERENV', 'LANGUAGE') as NLS_LANG_Parameter from dual;

ttitle left  "Session NLS Values" skip 2

column parameter format a24 heading "NLS Session Parameter"
column value     format a30 heading "Setting"
select  PARAMETER
       ,Value
 from nls_session_parameters 
order by 1
/ 

ttitle left  "Char set of the database" skip 2
column parameter format a24 heading "NLS DB Character Set"
select  PARAMETER
       ,Value
 from nls_database_parameters 
where parameter in ('NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET','NLS_LENGTH_SEMANTICS') 
order by 2
/ 

ttitle left  "NLS_LENGTH_SEMANTICS of the database" skip 2

show parameter NLS_LENGTH_SEMANTICS

prompt
prompt ... if NLS_LENGTH_SEMANTICS is byte new varchar2 columns will be defaulted to varchar2( xx byte)
prompt


ttitle off
