--==============================================================================
--
--==============================================================================
set linesize 130 pagesize 300 recsep off

SELECT  ss.instance_number
      , to_char(s.begin_interval_time,'dd.mm.yyyy hh24:mi') AS begin_interval_time
		, 'LOAD =>' AS param
		, round(ss.VALUE,3) AS load_value
FROM  dba_hist_snapshot s 
    , DBA_HIST_OSSTAT ss
	 , DBA_HIST_OSSTAT_NAME ssn
WHERE  s.snap_id = ss.snap_id 
  AND ss.instance_number = s.instance_number
  AND  s.snap_id > (SELECT MAX(i.snap_id)-10 FROM dba_hist_snapshot i WHERE i.instance_number=ss.instance_number)   
  AND ssn.stat_id=ss.stat_id
  AND ssn.stat_name='LOAD'
ORDER BY 1
 /