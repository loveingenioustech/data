create or replace PROCEDURE delete_publisher(i_schema_name     in varchar2,
                                             i_change_set_name in varchar2,
                                             i_options         in varchar2)
  authid current_user is
  cursor cur_change_tables is
    select distinct a.change_table_name
      from all_change_tables a
     where a.change_set_name = upper(i_change_set_name);

begin
  dbms_output.enable(50000);
  dbms_output.put_line('======================================== Start ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

  -- Delete all change tables 
  for r_tab in cur_change_tables loop
    dbms_output.put_line('>>> ' || r_tab.change_table_name);
  
    -- TODO add parse for i_options
    BEGIN
      DBMS_CDC_PUBLISH.DROP_CHANGE_TABLE(owner             => 'cdcpub',
                                         change_table_name => r_tab.change_table_name,
                                         force_flag        => 'Y');
    END;
  
    dbms_output.put_line('Delete Change Table: ' ||
                         r_tab.change_table_name || ' successfully!');
  
    dbms_output.put_line('<<< ' || r_tab.change_table_name);
    dbms_output.new_line();
  end loop;

  -- Delete change set
  BEGIN
    DBMS_CDC_PUBLISH.DROP_CHANGE_SET(change_set_name => upper(i_change_set_name));
  END;

  dbms_output.put_line('Delete Change Set: ' || i_change_set_name ||
                       ' successfully!');

  dbms_output.put_line('======================================== End ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

exception
  when others then
    dbms_output.put_line(SQLERRM);
end delete_publisher;
