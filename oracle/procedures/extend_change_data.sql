create or replace PROCEDURE extend_change_data(i_schema_name in varchar2,
                                               i_purge       in boolean) is
  v_subscription_name varchar2(30);
begin
  v_subscription_name := upper(i_schema_name) || '_SUB';

  -- Indicate that the current set of change data is no longer needed
  if nvl(i_purge, false) then
    BEGIN
      DBMS_CDC_SUBSCRIBE.PURGE_WINDOW(subscription_name => v_subscription_name);
    END;
    dbms_output.put_line('Purge window for: ' || v_subscription_name ||
                         ' successfully!');
  end if;

  -- Get the next set of change data
  BEGIN
    DBMS_CDC_SUBSCRIBE.EXTEND_WINDOW(subscription_name => v_subscription_name);
  END;
  dbms_output.put_line('Extend window for: ' || v_subscription_name ||
                       ' successfully!');
end extend_change_data;
