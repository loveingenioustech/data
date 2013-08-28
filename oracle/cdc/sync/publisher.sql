-- Publisher
-- Create a change set in cdcpub
BEGIN
  DBMS_CDC_PUBLISH.CREATE_CHANGE_SET(change_set_name    => 'EVENT_DAILY',
                                     description        => 'Change set for event info',
                                     change_source_name => 'SYNC_SOURCE');
END;
/

-- Create Change Table
BEGIN
  DBMS_CDC_PUBLISH.CREATE_CHANGE_TABLE(owner             => 'cdcpub',
                                       change_table_name => 'event_ct',
                                       change_set_name   => 'EVENT_DAILY',
                                       source_schema     => 'study',
                                       source_table      => 'EVENT',
                                       column_type_list  => 'id number,title VARCHAR2(50),title# VARCHAR2(50),start_date DATE,update_user_id VARCHAR2(50),update_time DATE',
                                       capture_values    => 'both',
                                       rs_id             => 'y',
                                       row_id            => 'n',
                                       user_id           => 'n',
                                       timestamp         => 'n',
                                       object_id         => 'n',
                                       source_colmap     => 'y',
                                       target_colmap     => 'y',
                                       DDL_MARKERS => 'n',
                                       options_string    => 'TABLESPACE TS_CDCPUB');
END;
/

-- Grant access to subscribers
grant select on event_ct to cdcsub;