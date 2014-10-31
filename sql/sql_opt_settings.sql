break on child_number skip 1    
 
select 
        child_number, name, value 
from    v$sql_optimizer_env 
where 
    sql_id = '2b1gpc9kurnav' 
order by 
        child_number, 
        name 
; 