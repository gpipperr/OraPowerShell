--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get DB roles
-- Date:   November 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

column role format a32

select role from dba_roles
/
