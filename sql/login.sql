--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   set the sqlplus prompt
-- Date:   01.September 2012
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET termout off
DEFINE _EDITOR=vi
col x new_value y
define y=?
SELECT SYS_CONTEXT('USERENV','HOST') x FROM dual;
SET sqlprompt "_USER'@'_CONNECT_IDENTIFIER-&y>"
SET termout ON

