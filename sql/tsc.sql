SET linesize 73 pagesize 300 recsep OFF

ttitle center "Tablespace statistics"  SKIP 1 -
       center "Sizes in MB" SKIP 2

define num = "format 999,990 heading"

COLUMN tablespace_name format a10 heading "Tablespace Name"
COLUMN df_size &&num "DF Size"
COLUMN df_used &&num "DF Used"
COLUMN df_free &&num "DF Free"
COLUMN potential &&num "Poten-|tial"
COLUMN max_free &&num "Max|Free"
COLUMN pct_free format 990.00 heading "% Free"
COLUMN scmael format a6

select dt.tablespace_name
      ,ROUND(capa.df_size / 1024 / 1024) df_size
      ,ROUND((capa.df_size - capa.df_free) / 1024 / 1024) df_used
      ,ROUND(capa.df_free / 1024 / 1024) df_free
      ,case
         when capa.pct_free <= 100 then
          (case
            when capa.pct_free >= 0 then
             capa.pct_free
            else
             0
          end)
         else
          100
       end pct_free
      ,ROUND(capa.potential / 1024 / 1024) potential
      ,ROUND(capa.max_free / 1024 / 1024) max_free
      ,(DECODE(dt.status, 'OFFLINE', 'F', 'O') || SUBSTR(CONTENTS, 1, 1) || SUBSTR(dt.extent_management, 1, 1) ||
       DECODE(dt.allocation_type, 'UNIF', 'F', SUBSTR(dt.allocation_type, 1, 1)) || SUBSTR(extensible, 1, 1) ||
       SUBSTR(dt.LOGGING, 1, 1)) scmael
  from DBA_TABLESPACES dt
      ,
       -- data files 
       (select a.tablespace_name
              ,df_size
              ,(allocated + potential) potential
              ,NVL(free, 0) df_free
              ,(NVL(f.max_free, 0) + potential) max_free
              ,(ROUND(NVL((NVL(free, 0) + potential) / (allocated + potential), 0), 4) * 100) pct_free
              ,extensible
          from ( -- free space in datafiles
                select tablespace_name
                       ,sum(b.blocks * t.block_size) free
                       ,max(b.blocks * t.block_size) max_free
                  from (select tablespace_id
                               ,blocks
                           from DBA_LMT_FREE_SPACE
                         union all
                         select tablespace_id
                               ,blocks
                           from DBA_DMT_FREE_SPACE) b
                       ,v$tablespace vt
                       ,DBA_TABLESPACES t
                 where vt.ts# = b.tablespace_id
                   and vt.NAME = t.tablespace_name
                 group by tablespace_name) f
              ,( -- allocated space in datafiles
                select tablespace_name
                       ,sum(case
                              when maxbytes <= bytes then
                               0
                              else
                               maxbytes - bytes
                            end) as potential
                       ,sum(user_bytes) allocated
                       ,sum(bytes) df_size
                       ,max(autoextensible) extensible
                  from DBA_DATA_FILES
                 group by tablespace_name) a
         where a.tablespace_name = f.tablespace_name(+)
        union all
        -- temp files 
        select t.tablespace_name
              ,df_size
              ,potential
              ,(allocated - NVL(used, 0)) as free
              ,
               -- max_free does not make sense for tempfiles, so null
               null as max_free
              ,(ROUND((potential - NVL(used, 0)) / potential, 4) * 100) pct_free
              ,extensible
          from ( -- used space in tempfiles
                select tablespace_name
                       ,sum(bytes_used) used
                  from v$temp_extent_pool
                 group by tablespace_name) e
              ,( -- allocated space in tempfiles
                select tablespace_name
                       ,sum(bytes) df_size
                       ,sum(case
                              when maxbytes <= bytes then
                               user_bytes
                              else
                               maxbytes - bytes + user_bytes
                            end) potential
                       ,sum(user_bytes) allocated
                       ,max(autoextensible) extensible
                  from DBA_TEMP_FILES
                 group by tablespace_name) t
         where t.tablespace_name = e.tablespace_name(+)) capa
 where dt.tablespace_name = capa.tablespace_name
 order by 1
/

prompt
prompt DF SIZE  : currently allocated sizes of datafiles 
prompt DF USED  : used part of currently allocated datafiles
prompt DF FREE  : free part of currently allocated datafiles
prompt % FREE   : % free including the potential maxsize of  
prompt .......... autoextensible datafiles 
prompt POTENTIAL: usable maxium size of the tablespace based   
prompt .......... on the potential maxsize of its autoextensible 
prompt .......... datafiles
prompt MAX FREE : maximum chunk of free space taking into account the   
prompt .......... potential maxsize of autoextensible datafiles
prompt SCMAEL...: S(tatus): O Online, F Offline
prompt .......... C(ontents): P Permanent, T Temporary, U Undo
prompt .......... M(anagement): L Local, D Dictionary
prompt .......... A(llocation type): S System, U User, F Uniform
prompt .......... E(autoextensible): Y contains, N does not contain 
prompt .......... autoextensible files
prompt .......... L(ogging): L Logging, N Nologging

ttitle off
