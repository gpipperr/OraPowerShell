SET termout off
DEFINE _EDITOR=vi
col x new_value y
define y=?
SELECT SYS_CONTEXT('USERENV','HOST') x FROM dual;
SET sqlprompt "_USER'@'_CONNECT_IDENTIFIER-&y>"
SET termout ON

