--==============================================================================
-- Desc:   
-- Date:   November 2013
--==============================================================================

select aa, hv
  from ( select /*+ ordered use_nl (b st) */
          decode( st.piece
                , 0
                , lpad(to_char((e.buffer_gets - nvl(b.buffer_gets,0))
                               ,'99,999,999,999')
                      ,15)||' '||
                  lpad(to_char((e.executions - nvl(b.executions,0))
                              ,'999,999,999')
                      ,12)||' '||
                  lpad((to_char(decode(e.executions - nvl(b.executions,0)
                                     ,0, to_number(null)
                                     ,(e.buffer_gets - nvl(b.buffer_gets,0)) /
                                      (e.executions - nvl(b.executions,0)))
                               ,'999,999,990.0'))
                      ,14) ||' '||
                  lpad((to_char(100*(e.buffer_gets - nvl(b.buffer_gets,0))/:gets
                               ,'990.0'))
                      , 6) ||' '||
                  lpad(  nvl(to_char(  (e.cpu_time - nvl(b.cpu_time,0))/1000000
                                   , '9990.00')
                       , ' '),8) || ' ' ||
                  lpad(  nvl(to_char(  (e.elapsed_time - nvl(b.elapsed_time,0))/1000000
                                   , '99990.00')
                       , ' '),9) || ' ' ||
                  lpad(e.old_hash_value,10)||''||
                  decode(e.module,null,st.sql_text
                                      ,rpad('Module: '||e.module,80)||st.sql_text)
                , st.sql_text) aa
          , e.old_hash_value hv
       from stats$sql_summary e
          , stats$sql_summary b
          , stats$sqltext     st 
      where b.snap_id(+)         = :bid
        and b.dbid(+)            = e.dbid
        and b.instance_number(+) = e.instance_number
        and b.old_hash_value(+)  = e.old_hash_value
        and b.address(+)         = e.address
        and b.text_subset(+)     = e.text_subset
        and e.snap_id            = :eid
        and e.dbid               = :dbid
        and e.instance_number    = :inst_num
        and e.old_hash_value     = st.old_hash_value 
        and e.text_subset        = st.text_subset
        and st.piece            <= &&num_rows_per_hash
        and e.executions         > nvl(b.executions,0)
        and 100*(e.buffer_gets - nvl(b.buffer_gets,0))/:gets > &&top_pct_sql
      order by (e.buffer_gets - nvl(b.buffer_gets,0)) desc, e.old_hash_value, st.piece
      )
where rownum < &&top_n_sql;