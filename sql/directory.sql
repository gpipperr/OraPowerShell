--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   show informations about directories in the database
-- Date:   08.08.2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================
SET linesize 130 pagesize 30 recsep OFF

ttitle  "Directories in the database"  SKIP 1 -
       center "Sizes in MB" SKIP 2
	   

column owner format a15
column directory_name format a25
column directory_path format a60

select owner
      ,directory_name
      ,directory_path
  from dba_directories
 order by 1
         ,2
/

ttitle off
