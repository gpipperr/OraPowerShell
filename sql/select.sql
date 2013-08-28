--==============================================================================
-- Author: Gunther Pippèrr ( http://www.pipperr.de )
-- Desc:   query some records from the table as list
-- Parameter 1: Name of the table
--
-- Site:   http://orapowershell.codeplex.com
-- Source see http://docs.oracle.com/cd/B28359_01/appdev.111/b28419/d_sql.htm#i996897
--==============================================================================

set verify  off

set linesize 120 pagesize 4000 recsep OFF

define TAB_NAME = '&1' 

prompt
prompt Parameter 1 = Tab Name         => &&TAB_NAME.
prompt

set serveroutput on

declare
  type curtype is ref cursor;
  src_cur        curtype;
  v_cursor_id    number;
  v_colType_var  varchar2(50);
  v_colType_num  number;
  v_colType_date date;
  v_tab_desc     dbms_sql.desc_tab;
  v_col_count    number;

  v_sql varchar2(1000) := 'select * from &&TAB_NAME. where rownum < 4';

begin
  dbms_output.put_line(rpad('=', 40, '='));
  dbms_output.put_line(rpad(rpad('-', 10, '-') || ' &&tab_name ', 40, '-'));
  dbms_output.put_line(rpad('=', 40, '='));
  -- open cursor for the sql statement
  open src_cur for v_sql;

  -- switch from native dynamic sql to dbms_sql package.
  v_cursor_id := dbms_sql.to_cursor_number(src_cur);
  dbms_sql.describe_columns(v_cursor_id, v_col_count, v_tab_desc);

  -- define columns.
  for i in 1 .. v_col_count
  loop
    if v_tab_desc(i).col_type = 2 then
      dbms_sql.define_column(v_cursor_id, i, v_colType_num);
    elsif v_tab_desc(i).col_type = 12 then
      dbms_sql.define_column(v_cursor_id, i, v_colType_date);
    else
      dbms_sql.define_column(v_cursor_id, i, v_colType_var, 50);
    end if;
  end loop;

  -- fetch rows with dbms_sql package.
  while dbms_sql.fetch_rows(v_cursor_id) > 0
  loop
    for i in 1 .. v_col_count
    loop
      
	  dbms_output.put(rpad(v_tab_desc(i).col_name, 30) || ' => ');
	  
      if (v_tab_desc(i).col_type = 1) then
        dbms_sql.column_value(v_cursor_id, i, v_colType_var);
        dbms_output.put_line(v_colType_var);
      elsif (v_tab_desc(i).col_type = 2) then
        dbms_sql.column_value(v_cursor_id, i, v_colType_num);
        dbms_output.put_line(v_colType_num);
      elsif (v_tab_desc(i).col_type = 12) then
        dbms_sql.column_value(v_cursor_id, i, v_colType_date);
        dbms_output.put_line(v_colType_date);
      end if;
    
	end loop;
    dbms_output.put_line(rpad('=', 40, '='));
  end loop;

  -- Close the cursor
  dbms_sql.close_cursor(v_cursor_id);

end;
/