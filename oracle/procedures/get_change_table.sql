create or replace PROCEDURE get_change_table(i_schema_name     in varchar2,
                                             i_change_set_name in varchar2)
  authid current_user is
  v_cnt             number;
  v_subscriber_view varchar2(30);
  v_sql             varchar2(200);

  cursor cur_subscribed_tables is
    select distinct a.view_name
      from all_subscribed_tables a
     where a.source_schema_name = upper(i_schema_name)
       and a.change_set_name = upper(i_change_set_name);

begin
  dbms_output.enable(50000);
  dbms_output.put_line('======================================== Start ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

  for r_tab in cur_subscribed_tables loop
    v_sql             := '';
    v_subscriber_view := r_tab.view_name;
  
    v_sql := 'select count(*) from ' || v_subscriber_view;
  
    begin
      execute immediate v_sql
        into v_cnt;
    
      if v_cnt > 0 then
        dbms_output.put_line(r_tab.view_name ||
                             ' changed, change records count: ' || v_cnt);
      end if;
    end;
  
  end loop;

  dbms_output.put_line('======================================== End ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');
end get_change_table;
