create or replace PROCEDURE get_change_table(i_schema_name  in varchar2,
                                             i_table_prefix in varchar2)
  authid current_user is
  v_cnt             number;
  v_subscriber_view varchar2(30);
  v_sql             varchar2(200);
  cursor cur_source_tables is
    select distinct a.TABLE_NAME
      from all_tables a
     where a.OWNER = upper(i_schema_name)
       and a.STATUS = 'VALID'
       and a.TABLE_NAME like upper(nvl(i_table_prefix, '%')) || '%';

begin

  for r_tab in cur_source_tables loop
    v_sql             := '';
    v_subscriber_view := r_tab.TABLE_NAME || '_VIEW';
  
    v_sql := 'select count(*) from ' || v_subscriber_view;
  
    begin
      execute immediate v_sql
        into v_cnt;
    
      if v_cnt > 0 then
        dbms_output.put_line(r_tab.TABLE_NAME ||
                             ' changed, change records count: ' || v_cnt);
      end if;
    end;
  
  end loop;

end get_change_table;
