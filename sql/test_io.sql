--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script to check the size of a table
-- Doku:   http://www.pipperr.de/dokuwiki/doku.php?id=dba:sql_groesse_tabelle
-- Date:   08.2013
-- Site:   http://orapowershell.codeplex.com
---         http://docs.oracle.com/cd/E11882_01/appdev.112/e25788/d_resmgr.htm#CJGHGFEA
--==============================================================================

set pagesize 300
set linesize 150

set verify off

set serveroutput on

declare
  lat  integer;
  iops integer;
  mbps integer;
begin
  --dbms_resource_manager.calibrate_io (1, 10, iops, mbps, lat);
  dbms_output.put_line('max_iops = ' || iops);
  dbms_output.put_line('latency  = ' || lat);
  dbms_output.put_line('max_mbps = ' || mbps);
end;
/


column start_time format a25
column end_time format a25

select * from dba_rsrc_io_calibrate
/

column name format a35
select
     d.name
   , f.file_no
   , f.small_read_megabytes
   , f.small_read_reqs
   , f.large_read_megabytes
   , f.large_read_reqs
from
   v$iostat_file f
   inner join v$datafile d on f.file_no = d.file#
/