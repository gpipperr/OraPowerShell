--==============================================================================
-- GPI -  Gunther Pippèrr
-- Desc:   DB Links
-- Date:   01.September 2012
--
--==============================================================================
set linesize 130 pagesize 300 recsep off

prompt
prompt Link Infos -- The DB Links this user can see
prompt 

column owner format a14
column host  format a60
column db_link format a25
column username format a20


select db_link
      , host
	  , owner 
	  , username
from all_db_links
 /


ttitle left  "Link Infos -- All DB Links in the database" skip 2

select db_link
	  , owner 
	  , host
	  , username
from dba_db_links
 /

 
ttitle off

prompt ...
prompt ... to create a private db link use this statement:
prompt ... "CREATE DATABASE LINK mylink CONNECT TO remote_user IDENTIFIED BY remote_pwd USING 'remote_db';"
prompt ... to get the DDL of all links use links_ddl.sql
prompt ...

