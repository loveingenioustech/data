create or replace PROCEDURE create_publisher(i_schema_name     in varchar2,
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

  v_description       varchar2(2000);
  v_column_type_list  varchar2(2000);
  v_change_table_name varchar2(50);
  v_grant_sql         varchar2(200);
  v_cs_cnt            number := 0;
  v_ct_cnt            number;
  v_data_length       number;
begin
  dbms_output.enable(50000);
  dbms_output.put_line('======================================== Start ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

  -- Create change set 
  -- One change set for one schema
  select count(*)
    into v_cs_cnt
    from all_change_sets a
   where a.set_name = upper(i_change_set_name);

  if v_cs_cnt = 0 then
    if i_description is null then
      v_description := 'Change set for schema: ' || upper(i_schema_name);
    else
      v_description := i_description || ': ' || 'Change set for schema: ' ||
                       upper(i_schema_name);
    end if;
  
    BEGIN
    
      DBMS_CDC_PUBLISH.CREATE_CHANGE_SET(change_set_name    => upper(i_change_set_name),
                                         description        => 'Change set for event info',
                                         change_source_name => 'SYNC_SOURCE');
    
      dbms_output.put_line('Create change set: ' ||
                           upper(i_change_set_name) || ' successfully!');
    
    END;
  else
    dbms_output.put_line('Change set: ' || upper(i_change_set_name) ||
                         ' already exists!');
  
  end if;

  for r in cur_source_tables loop
    dbms_output.put_line('>>> ' || r.TABLE_NAME);
    -- Create Change Table
    v_change_table_name := r.TABLE_NAME || '_CT';
  
    if length(v_change_table_name) > 30 then
      v_change_table_name := substr(v_change_table_name, 1, 30);
    end if;
  
    v_ct_cnt := 0;
    select count(*)
      into v_ct_cnt
      from all_change_tables a
     where a.change_table_schema = 'CDCPUB'
       and a.change_set_name = upper(i_change_set_name)
       and a.change_table_name = v_change_table_name;
  
    if v_ct_cnt = 0 then
      v_column_type_list := '';
      for r_col in cur_table_cols(r.TABLE_NAME) loop
        -- Common for all data types
        v_column_type_list := v_column_type_list || '"' ||
                              r_col.COLUMN_NAME || '" ' || r_col.DATA_TYPE;
      
        if r_col.DATA_TYPE = 'CHAR' or r_col.DATA_TYPE = 'NCHAR' or
           r_col.DATA_TYPE = 'NVARCHAR2' or r_col.DATA_TYPE = 'VARCHAR2' or
           r_col.DATA_TYPE = 'RAW' then
        
          if r_col.DATA_TYPE = 'NVARCHAR2' then
            v_data_length := r_col.DATA_LENGTH / 2;
          else
            v_data_length := r_col.DATA_LENGTH;
          end if;
        
          v_column_type_list := v_column_type_list || '(' || v_data_length || ')';
        end if;
      
        if r_col.DATA_TYPE = 'NUMBER' then
          if nvl(r_col.DATA_PRECISION, 0) <> 0 then
            v_column_type_list := v_column_type_list || '(' ||
                                  r_col.DATA_PRECISION;
          
            if nvl(r_col.DATA_SCALE, 0) <> 0 then
              v_column_type_list := v_column_type_list || ',' ||
                                    r_col.DATA_SCALE || ')';
            else
              v_column_type_list := v_column_type_list || ')';
            end if;
          end if;
        
        end if;
      
        v_column_type_list := v_column_type_list || ',';
      end loop;
    
      -- remove last comma
      v_column_type_list := substr(v_column_type_list,
                                   1,
                                   length(v_column_type_list) - 1);
    
      /*      
      if length(v_column_type_list) > 255 then
        dbms_output.put_line('column_type_list for table - ' ||
                             r.TABLE_NAME || ': ');
      
        for i in 1 .. ceil(length(v_column_type_list) / 255) loop
          dbms_output.put_line(substr(v_column_type_list,
                                      (i - 1) * 255 + 1,
                                      255));
        end loop;
      else
        dbms_output.put_line('column_type_list for table - ' ||
                             r.TABLE_NAME || ': ' || v_column_type_list);
      end if;
      */
    
      -- TODO add parse for i_options
      BEGIN
        DBMS_CDC_PUBLISH.CREATE_CHANGE_TABLE(owner             => 'cdcpub',
                                             change_table_name => v_change_table_name,
                                             change_set_name   => upper(i_change_set_name),
                                             source_schema     => upper(i_schema_name),
                                             source_table      => r.TABLE_NAME,
                                             column_type_list  => v_column_type_list,
                                             capture_values    => 'both',
                                             rs_id             => 'y',
                                             row_id            => 'n',
                                             user_id           => 'n',
                                             timestamp         => 'n',
                                             object_id         => 'n',
                                             source_colmap     => 'y',
                                             target_colmap     => 'y',
                                             DDL_MARKERS       => 'n',
                                             options_string    => 'TABLESPACE TS_CDCPUB');
      END;
    
      dbms_output.put_line('Create Change Table: ' || r.TABLE_NAME ||
                           ' successfully!');
    
    else
      dbms_output.put_line('Change Table: ' || r.TABLE_NAME ||
                           ' already exists!');
    end if;
  
    -- Grant access to subscribers
    v_grant_sql := 'grant select on ' || v_change_table_name ||
                   ' to cdcsub';
  
    BEGIN
      execute immediate v_grant_sql;
    END;
    dbms_output.put_line('Grant: ' || v_grant_sql);
  
    dbms_output.put_line('<<< ' || r.TABLE_NAME);
    dbms_output.new_line();
  end loop;

  dbms_output.put_line('======================================== End ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

exception
  when others then
    dbms_output.put_line(SQLERRM);
end create_publisher;
