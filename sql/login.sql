--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   set the sqlplus prompt
--         try to find out the os of sqlplus and set the title bar of the sql*Plus window if windows
-- 
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET termout off

-- get the host name

col x new_value y
define y=?
-- use only the first part of the host name to avoid error with value to long
select decode(substr(SYS_CONTEXT('USERENV', 'SERVER_HOST'), 1, instr(SYS_CONTEXT('USERENV', 'SERVER_HOST'), '.') - 1), '',
              SYS_CONTEXT('USERENV', 'SERVER_HOST'),
              substr(SYS_CONTEXT('USERENV', 'SERVER_HOST'), 1, instr(SYS_CONTEXT('USERENV', 'SERVER_HOST'), '.') - 1)) x
  from dual
/ 

-- get the data for the window title

col u new_value z
define z=?
select SYS_CONTEXT('USERENV', 'INSTANCE_NAME')||' ++ Service :: '||SYS_CONTEXT('USERENV', 'SERVICE_NAME') || ' ++ User :: '||user u
  from dual
/

-- the the operation System to set the title bar of the sqlplus window
-- the problem is the the detection of the operation system of sqlplus 
-- to call the right os command to set the title window

-- try to the the os from a return code
-- not working, error out is bad....
-- if command uptime exits we guess linux
--
-- WHENEVER OSERROR continue
-- 
-- --host set 
-- var HR varchar2(5)
-- 
-- set verify off
-- get the return code from host 
-- begin
--  :HR := '&_RC';
-- end;
-- /
-- set verify on

--------

var OS varchar2(5)

declare
 v_oracle_home varchar2(512);
 v_module  varchar2(512);
 v_os_user varchar2(512);
 v_host    varchar2(512);
begin
	:OS:='XX';    
	
	-- try to get the OS from the Oracle Home Path 
	-- only possible if you have DBA rights 
	if ( SYS_CONTEXT('USERENV', 'ISDBA') != 'FALSE' )
	then
		
		-- dbms_system is only valid if you are dba
		-- must be called there for dynamic!
		-- but this is not the client environment ...
		-- execute immediate 'begin dbms_system.get_env(''ORACLE_HOME'',:1); end;' using out v_oracle_home;
		-- if instr(v_oracle_home,'/') > 0 then
		--
		
		-- if you are dba you will see sqlplus.exe
		-- use the .exe to detect windows
		
		v_module:=SYS_CONTEXT('USERENV', 'MODULE');
		
		if instr(v_module,'.exe') > 0 then
			:OS:='WIN';
		else
			:OS:='LINUX';
		end if;
		
	else     
	    -- try to check if sqlplus was started from a windows environment
		-- the windows login name is host\user 
		-- try to detect the \
	
		v_os_user:= SYS_CONTEXT('USERENV', 'OS_USER');
		v_host   := SYS_CONTEXT('USERENV', 'HOST');
	    
		if instr(v_os_user,'\') > 0 then
		    -- ' needed for syntax highlightning of my editor ...
			:OS:='WIN';
		else
		    --  check  again the with the host
			if instr(v_host,'\') > 0 then
			-- ' needed for syntax highlightning of my editor ...
				:OS:='WIN';
			else
				:OS:='LINUX';
			end if;
		end if;
		
	end if;
end;
/

--- define  this variable to avoid error with nolog logins 
define SCRIPTPART_CALL='set_no_titel.sql'

col SCRIPTPART_COL new_val SCRIPTPART_CALL
 
SELECT decode(:OS
			,'LINUX'
			,'set_linux_title.sql'
			,'set_windows_title.sql'
		) AS SCRIPTPART_COL
FROM dual
/

undefine OS 

-- call the os script for the title setting
-- 
@@&&SCRIPTPART_CALL "&z" "&y"

SET sqlprompt "_USER'@'_CONNECT_IDENTIFIER-&y>"


--- global Settings
set trimspool on
set serveroutput on
set pagesize 100
set linesize 130
-- suppress scientific notation
set NUMWIDTH  12
--
SET termout ON
--
alter session set NLS_DATE_FORMAT='dd.mm.RR hh24:mi';



