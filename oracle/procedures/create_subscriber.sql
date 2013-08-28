create or replace PROCEDURE create_subscriber(i_schema_name     in varchar2,
                                              i_change_set_name in varchar2,
                                              i_description     in varchar2,
                                              i_table_prefix    in varchar2,
                                              i_options         in varchar2)
  authid current_user is
  cursor cur_source_tables is
    select distinct a.TABLE_NAME
      from all_tables a
     where a.OWNER = upper(i_schema_name)
       and a.STATUS = 'VALID'
       and a.TABLE_NAME like upper(nvl(i_table_prefix, '%')) || '%';

  cursor cur_table_cols(p_table_name in varchar2) is
    select a.COLUMN_NAME,
           a.DATA_TYPE,
           a.DATA_LENGTH,
           a.DATA_PRECISION,
           a.DATA_SCALE
      from all_tab_columns a
     where a.OWNER = upper(i_schema_name)
       and a.TABLE_NAME = upper(p_table_name);

  v_description varchar2(2000);
  v_column_list varchar2(2000);

  v_change_table_name varchar2(30);
  v_subscription_name varchar2(30);
  v_subscriber_view   varchar2(30);
  v_sub_cnt           number := 0;
  v_st_cnt            number;

begin
  dbms_output.enable(50000);
  dbms_output.put_line('======================================== Start ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

  -- Create a subscription
  -- One subscription set for one schema
  v_subscription_name := upper(i_schema_name) || '_SUB';

  select count(*)
    into v_sub_cnt
    from all_subscriptions a
   where a.username = 'CDCSUB'
     and a.set_name = upper(i_change_set_name)
     and a.subscription_name = v_subscription_name;

  if v_sub_cnt = 0 then
    if i_description is null then
      v_description := 'Change data for schema: ' || upper(i_schema_name);
    else
      v_description := i_description || ': ' || 'Change data for schema: ' ||
                       upper(i_schema_name);
    end if;
  
    BEGIN
      DBMS_CDC_SUBSCRIBE.CREATE_SUBSCRIPTION(change_set_name   => upper(i_change_set_name),
                                             description       => 'Change data for event',
                                             subscription_name => v_subscription_name);
    END;
  
    dbms_output.put_line('Create subscription: ' || v_subscription_name ||
                         ' successfully!');
  else
    DBMS_CDC_SUBSCRIBE.DROP_SUBSCRIPTION(subscription_name => v_subscription_name);
  
    DBMS_CDC_SUBSCRIBE.CREATE_SUBSCRIPTION(change_set_name   => upper(i_change_set_name),
                                           description       => 'Change data for event',
                                           subscription_name => v_subscription_name);
  
    dbms_output.put_line('Re-create subscription: ' || v_subscription_name ||
                         ' successfully!');
  
  end if;

  -- loop all source tables 
  for r_tab in cur_source_tables loop
    -- Subscribe to a source table and the columns in the source table
    v_subscriber_view := r_tab.TABLE_NAME || '_VIEW';
    v_st_cnt          := 0;
  
    select count(*)
      into v_st_cnt
      from all_subscribed_tables a
     where a.source_schema_name = upper(i_schema_name)
       and a.subscription_name = v_subscription_name
       and a.source_table_name = r_tab.TABLE_NAME;
  
    if v_st_cnt = 0 then
      v_column_list := ''; 
      for r_col in cur_table_cols(r_tab.TABLE_NAME) loop
        v_column_list := v_column_list || r_col.COLUMN_NAME || ',';
      end loop;
    
      -- remove last comma
      v_column_list := substr(v_column_list, 1, length(v_column_list) - 1);
      dbms_output.put_line('column_type_list for table - ' ||
                           r_tab.TABLE_NAME || ': ' || v_column_list);
    
      BEGIN
        DBMS_CDC_SUBSCRIBE.SUBSCRIBE(subscription_name => v_subscription_name,
                                     source_schema     => upper(i_schema_name),
                                     source_table      => r_tab.TABLE_NAME,
                                     column_list       => v_column_list,
                                     subscriber_view   => v_subscriber_view);
      END;
    
      dbms_output.put_line('Subscribed source table: ' || r_tab.TABLE_NAME ||
                           ' successfully!');
    else
      dbms_output.put_line('Source table: ' || r_tab.TABLE_NAME ||
                           ' already subscribed!');
    end if;
  
  end loop;

  -- Activate the subscription
  BEGIN
    DBMS_CDC_SUBSCRIBE.ACTIVATE_SUBSCRIPTION(subscription_name => v_subscription_name);
  END;
  dbms_output.put_line('Activated: ' || v_subscription_name ||
                       ' successfully!');

  dbms_output.put_line('======================================== End ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

exception
  when others then
    dbms_output.put_line(SQLERRM);
end create_subscriber;
