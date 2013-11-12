--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   get the xml DB Configuration
-- Date:   November 2013

-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 130 pagesize 9000 recsep OFF

ttitle  "XML DB Configuration"  SKIP 2

set long 100000

select dbms_xdb.cfg_get from dual
/

ttitle off

