SET linesize 130

ttitle left  "Workload Statistik Values" skip 2

column SNAME format a20
column pname format a15
column PVAL2 format a20

select SNAME,
 PNAME,
 PVAL1,
 PVAL2 from sys.aux_stats$
/

ttitle left  "LAST ANALYZED Tables Overview" skip 2

column last format a14
SELECT   to_char(LAST_ANALYZED,'dd.mm.yyyy hh24') as last
       , owner
       , count(*)  
  from dba_tables 
 group by owner,to_char(LAST_ANALYZED,'dd.mm.yyyy hh24') 
 order by 1 desc;

ttitle off
 
 
