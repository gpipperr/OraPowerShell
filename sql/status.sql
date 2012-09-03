ttitle left  "Status all Instances" skip 2
column inst_id format 9
column status  format A8
column name  format A8
column startzeit format A15

select inst_id as id
     , status
	   , instance_name as name 
	   , to_char(STARTUP_TIME,'dd.mm.YY hh24:mi') as startzeit
 from gv$instance 
order by 1
/

ttitle off

