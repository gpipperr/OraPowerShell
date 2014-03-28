--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   show the object count of none default users
-- Date:   October 2013
-- Site:   http://orapowershell.codeplex.com
--==============================================================================

SET linesize 73 pagesize 400 recsep OFF

column OWNER format a25  

select owner
     , obj_type
	  , obj_count 
	  , sum(size_GB) as size_GB
 from (
	select count(*) as obj_count, o.object_type as obj_type, o.owner  ,round( sum(s.bytes) /1024/1024/1024 , 3) as size_GB
	  from dba_objects o, dba_segments s
	 where s.owner=o.owner
	   and s.segment_name =o.object_name(+)
	 group by o.object_type,o.owner
 ) 
where owner not in ('SYS','MDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','ORDDATA','ORDSYS','EXFSYS','XS$NULL','XDB','CTXSYS','WMSYS','APPQOSSYS','DBSNMP','ORACLE_OCM','DIP','OUTLN','SYSTEM','FLOWS_FILES','PUBLIC','SYSMAN','OLAPSYS','OWBSYS','OWBSYS_AUDIT')
and obj_type in ('TABLE','INDEX')
group by owner,obj_type,obj_count
order by owner,obj_type
/
