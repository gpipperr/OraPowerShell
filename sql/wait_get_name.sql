----
-- get the name of a wait statistic
----

define SYSSTAT_NAME = &1


prompt
prompt Parameter 1 = SYSSTAT_NAME     => &&SYSSTAT_NAME.
prompt

SET pagesize 1000
SET linesize 250


------------------------------------------------------------
TTITLE 'Search after all waits statistics with this name &&SYSSTAT_NAME.' skip 2


select statistic#
	  , name
	  , class
 from v$statname 
where name like '&&SYSSTAT_NAME.%'
order by 2
/


TTITLE off
