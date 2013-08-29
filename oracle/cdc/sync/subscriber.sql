-- Subscriber 

-- Find the source tables for which the subscriber has access privileges
SELECT * FROM DBA_SOURCE_TABLES;

-- Find the change set names and columns for which the subscriber has access privileges
select change_set_name,pub_id,source_table_name from DBA_PUBLISHED_COLUMNS;
SELECT UNIQUE CHANGE_SET_NAME, COLUMN_NAME, PUB_ID 
FROM DBA_PUBLISHED_COLUMNS;

-- Create a subscription
BEGIN
  DBMS_CDC_SUBSCRIBE.CREATE_SUBSCRIPTION(change_set_name   => 'EVENT_DAILY',
                                         description       => 'Change data for event',
                                         subscription_name => 'EVENT_SUB');
END;
/

-- Subscribe to a source table and the columns in the source table
BEGIN
  DBMS_CDC_SUBSCRIBE.SUBSCRIBE(subscription_name => 'EVENT_SUB',
                               source_schema     => 'study',
                               source_table      => 'event',
                               column_list       => 'id, title, title#, start_date, update_user_id, update_time',
                               subscriber_view   => 'EVENT_VIEW');
END;
/

-- Activate the subscription
BEGIN
  DBMS_CDC_SUBSCRIBE.ACTIVATE_SUBSCRIPTION(subscription_name => 'EVENT_SUB');
END;
/

-- Get the next set of change data
BEGIN
  DBMS_CDC_SUBSCRIBE.EXTEND_WINDOW(subscription_name => 'EVENT_SUB');
END;
/

-- Read and query the contents of the subscriber views
SELECT * FROM EVENT_VIEW;

-- Be careful
-- Indicate that the current set of change data is no longer needed
BEGIN
  DBMS_CDC_SUBSCRIBE.PURGE_WINDOW(subscription_name => 'EVENT_SUB');
END;
/

-- End the subscription
-- When drop subscription, also droped all subscribed tables in the subscription
BEGIN
  DBMS_CDC_SUBSCRIBE.DROP_SUBSCRIPTION(subscription_name => 'EVENT_SUB');
END;
/

select * from all_subscriptions a;
select * from all_subscribed_tables a;
select * from all_subscribed_columns a;