-- ==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   SQL Script to check the size of a table
-- Doku:   http://www.pipperr.de/dokuwiki/doku.php?id=dba:sql_groesse_tabelle
-- Date:   08.2013
-- Site:   http://orapowershell.codeplex.com
-- ==============================================================================

SET pagesize 300
SET linesize 250
SET VERIFY OFF

define lnum  = "format 9G999G999D99"
define num   = "format 99G999"
define snum  = "format 9G999"

ttitle left  "Space Usage of a table" skip 2

define ENTER_OWNER='&TABLE_OWNER'
define ENTER_TABLE='&TABLE_NAME'

column segment_name format A20
column owner        format A10
column Size_MB 		&&lnum
column count_blk 	&&num 
column count_ext 	&&snum
column count_part 	&&snum

select segment_name
      ,owner
      ,round(sum(bytes) / 1024 / 1024, 3) as Size_MB
      ,sum(blocks) as count_blk
      ,sum(EXTENTS) as count_ext
      ,count(*) as count_part
  from dba_segments
 where upper(segment_name) like upper('&ENTER_TABLE.%')
   and upper(owner) = upper('&ENTER_OWNER.')
 group by segment_name
         ,owner
/

/*
Parameter			Description
-----------------------------------------------------------------------
segment_owner		Schema name of the segment to be analyzed
segment_name		Name of the segment to be analyzed
partition_name		Partition name of the segment to be analyzed
segment_type		Type of the segment to be analyzed (TABLE, INDEX, or CLUSTER)
unformatted_blocks	Total number of blocks that are unformatted
unformatted bytes	Total number of bytes that are unformatted
fs1_blocks			Number of blocks that has at least 0 to 25% free space
fs1_bytes			Number of bytes that has at least 0 to 25% free space
fs2_blocks			Number of blocks that has at least 25 to 50% free space
fs2_bytes			Number of bytes that has at least 25 to 50% free space
fs3_blocks			Number of blocks that has at least 50 to 75% free space
fs3_bytes			Number of bytes that has at least 50 to 75% free space
fs4_blocks			Number of blocks that has at least 75 to 100% free space
fs4_bytes			Number of bytes that has at least 75 to 100% free space
ful1_blocks			Total number of blocks that are full in the segment
full_bytes			Total number of bytes that are full in the segment


----------------------------

total_blocks				Returns total number of blocks in the segment.
total_bytes					Returns total number of blocks in the segment, in bytes.
unused_blocks				Returns number of blocks which are not used.
unused_bytes				Returns, in bytes, number of blocks which are not used.
last_used_extent_ file_id	Returns the file ID of the last extent which contains data.
last_used_extent_ block_id	Returns the starting block ID of the last extent which contains data.
last_used_block				Returns the last block within this extent which contains data.

*/

set serveroutput on

declare
  unf number;
  unfb number;
  fs1 number;
  fs1b number;
  fs2 number;
  fs2b number;
  fs3 number;
  fs3b number;
  fs4 number;
  fs4b number;
  full number;
  fullb number;
  
  total_blocks number;
  total_bytes number;
  unused_blocks number;
  unused_bytes number;
  lastextf number;
  last_extb number;
  lastusedblock number;

  v_file_name dba_data_files.file_name%type;
  v_tablespace_name dba_segments.TABLESPACE_NAME%type;
  v_segment_management dba_tablespaces.SEGMENT_SPACE_MANAGEMENT%type;
  
  cursor c_seg is
	select  segment_name
	      , owner 
		  , SEGMENT_TYPE
	  from dba_segments  
	 where upper(segment_name) like upper('&ENTER_TABLE.%')  and upper(owner)=upper('&ENTER_OWNER.');
  
begin

	for rec in  c_seg
	loop

		begin 
		  dbms_output.put_line('Info -- Call dbms_space.space_usage for table ( Type:'|| rec.segment_type||' ) ::'||rec.segment_name);
		  dbms_output.put_line('Info ------------------------------------------------------------------');
		  
		  dbms_space.space_usage(rec.owner,rec.segment_name,rec.segment_type,unf,unfb,fs1,fs1b,fs2,fs2b,fs3,fs3b,fs4,fs4b,full,fullb);
		  
		  dbms_output.put_line('Info -- Total Count of blocks that are unformatted              :'||unf ||' Bytes :'||unfb);
		  dbms_output.put_line('Info -- Total Count of blocks that are full in the segment      :'||full||' Bytes :'||fullb);
		  
		  dbms_output.put_line('Info -- ');
		  
		  dbms_output.put_line('Info -- Count of blocks that has at least 0  to 25%  free space :'||fs1||' Bytes :'||fs1b);
		  dbms_output.put_line('Info -- Count of blocks that has at least 25 to 50%  free space :'||fs2||' Bytes :'||fs2b);
		  dbms_output.put_line('Info -- Count of blocks that has at least 50 to 75%  free space :'||fs3||' Bytes :'||fs3b);
		  dbms_output.put_line('Info -- Count of blocks that has at least 75 to 100% free space :'||fs4||' Bytes :'||fs4b);
		  
		  dbms_output.put_line('Info ------------------------------------------------------------------');
		 exception
		  when others then
				dbms_output.put_line('Error --');
				dbms_output.put_line('Error -- '||SQLERRM);
				dbms_output.put_line('Error --   +This procedure can be used only on segments in  tablespaces with AUTO SEGMENT SPACE MANAGEMENT');
				dbms_output.put_line('Error --   +Action:  Recheck the segment name and type and re-issue the statement');
				select s.TABLESPACE_NAME , t.SEGMENT_SPACE_MANAGEMENT into v_tablespace_name , v_segment_management
				 from dba_segments s , dba_tablespaces t
				where upper(s.segment_name) like upper('&ENTER_TABLE.%')   
				  and upper(s.owner)=upper('&ENTER_OWNER.')
				  and s.TABLESPACE_NAME=t.TABLESPACE_NAME;
				  
				dbms_output.put_line('Error --   +Tablespace for the table &ENTER_TABLE.:: '||v_tablespace_name ||' - Segment Management for this tablespace:: '||v_segment_management);
				dbms_output.put_line('Error --');
		 end;
	 
		 begin 
		  dbms_output.put_line('Info -- Call dbms_space.UNUSED_SPACE for table  ( Type:'|| rec.segment_type||' ) ::'||rec.segment_name);
		  
		  dbms_space.UNUSED_SPACE(rec.owner,rec.segment_name,rec.segment_type, total_blocks,  total_bytes, unused_blocks, unused_bytes, lastextf, last_extb, lastusedblock); 
		  
		  dbms_output.put_line('Info ------------------------------------------------------------------');
		  dbms_output.put_line('Info -- Used total_blocks                           :'|| total_blocks);
		  dbms_output.put_line('Info -- Used total_bytes                            :'|| total_bytes );
		  dbms_output.put_line('Info -- Unused block                                :'|| unused_blocks );
		  dbms_output.put_line('Info -- Unused byte                                 :'|| unused_bytes );
		  dbms_output.put_line('Info -- File ID of the last extent with data        :'|| lastextf );
		  
		  select file_name into v_file_name from dba_data_files where FILE_ID=lastextf;
		   
		  dbms_output.put_line('Info -- File Name last extent with data             :'|| v_file_name );
		  
		  dbms_output.put_line('Info -- Starting block ID of the last extent        :'|| last_extb );
		  dbms_output.put_line('Info -- Last block within this extent               :'|| lastusedblock );
		  dbms_output.put_line('Info ------------------------------------------------------------------');
		  
		  exception
		  when others then
			 dbms_output.put_line('Error ---'||SQLERRM);
		 end;
	
	end loop;
 
end;
/ 

SET VERIFY ON
ttitle off

