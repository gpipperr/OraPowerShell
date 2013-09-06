--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   set the sqlplus prompt
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET termout off

DEFINE _EDITOR=vi

-- get the hostname
col x new_value y
define y=?
-- use only the first part of the hostname to avoid error with value to long
select decode(substr(SYS_CONTEXT('USERENV', 'HOST'), 1, instr(SYS_CONTEXT('USERENV', 'HOST'), '.') - 1), '',
              SYS_CONTEXT('USERENV', 'HOST'),
              substr(SYS_CONTEXT('USERENV', 'HOST'), 1, instr(SYS_CONTEXT('USERENV', 'HOST'), '.') - 1)) x
  from dual
/ 

-- get the user
col u new_value z
define z=?
select user u
  from dual
/


-- set the title 
$ title Sql*plus window :: &z -- &y

SET sqlprompt "_USER'@'_CONNECT_IDENTIFIER-&y>"

SET termout ON
