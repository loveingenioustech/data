CREATE OR REPLACE PACKAGE common_util AS

  Type t_string_array is table of varchar2(4000);

  TYPE t_string_table IS TABLE OF VARCHAR(20) INDEX BY BINARY_INTEGER;

  -- return pattern matches as array
  -- select * from table(common_util.match('select from event', '\from\'));
  function match(i_str in varchar2, i_pattern in varchar2)
    return t_string_array
    pipelined;

  function find(i_str in clob, i_pattern in varchar2) return t_string_array;

  PROCEDURE find_sql_plan(i_schema_name      IN varchar2,
                          i_table_prefix     in varchar2,
                          i_estimate_percent in number,
                          i_magnify_times    in number);
                          
  function  createTokenList(pLine IN VARCHAR2, pDelimiter IN VARCHAR2)
    RETURN t_string_table;                                                 
END common_util;


CREATE OR REPLACE PACKAGE BODY common_util AS

  function match(i_str in varchar2, i_pattern in varchar2)
    return t_string_array
    pipelined as
    v_val varchar2(4000);
    v_cnt pls_integer := 1;
  begin
    dbms_output.put_line('Match function 1');
    if i_str is not null then
      loop
        v_val := regexp_substr(i_str, i_pattern, 1, v_cnt);
        if v_val is null then
          exit;
        else
          v_cnt := v_cnt + 1;
          pipe row(v_val);
        end if;
      end loop;
    end if;
  
    return;
  end match;

  function find(i_str in clob, i_pattern in varchar2) return t_string_array as
    v_val    varchar2(4000);
    v_idx    pls_integer := 0;
    v_cnt    pls_integer := 1;
    v_matchs t_string_array;
  begin
    dbms_output.put_line('Match function 2');
  
    v_matchs := t_string_array();
  
    if i_str is not null then
    
      loop
        v_val := regexp_substr(i_str, i_pattern, 1, v_cnt);
      
        if v_val is null then
          exit;
        else
          v_cnt := v_cnt + 1;
          v_idx := v_idx + 1;
          v_matchs.extend;
          v_matchs(v_idx) := v_val;
        end if;
      end loop;
    end if;
  
    return v_matchs;
  end find;

  function find_table_name(i_sql_text clob,
                           i_pre      varchar2,
                           i_pattern  varchar2) return t_string_array as
    v_sql_text    clob;
    v_start       number;
    v_end         number;
    v_idx         number;
    v_table_name  varchar2(30);
    v_table_names t_string_array;
  begin
    -- process original sql text, replace new line character
    v_sql_text := lower(replace(replace(i_sql_text, chr(13), ' '),
                                chr(10),
                                ' '));
  
    v_start       := instr(v_sql_text, i_pre);
    v_start       := instr(v_sql_text, i_pattern, v_start);
    v_end         := 0;
    v_idx         := 0;
    v_table_names := t_string_array();
  
    while v_start != 0 loop
      if v_start != 0 then
        v_end := instr(v_sql_text, ' ', v_start + 1);
        if v_end = 0 then
          v_table_name := substr(v_sql_text, v_start);
        else
          v_table_name := substr(v_sql_text, v_start, v_end - v_start);
        end if;
      
        v_table_name := replace(replace(v_table_name, '''', ''), '"', '');
        v_idx        := v_idx + 1;
        v_table_names.extend;
        v_table_names(v_idx) := v_table_name;
      end if;
      v_start := instr(v_sql_text, i_pattern, v_end);
    end loop;
  
    return v_table_names;
  end find_table_name;

  PROCEDURE find_sql_plan(i_schema_name      IN varchar2,
                          i_table_prefix     in varchar2,
                          i_estimate_percent in number,
                          i_magnify_times    in number) is
    CURSOR cur_sql_plan is
      select distinct dbms_lob.substr(v.SQL_FULLTEXT, 4000, 1) as sql_fulltext,
                      dbms_lob.substr(v.SQL_FULLTEXT, 4001, 8000) as sql_fulltext_suppl,
                      v.first_load_time
        from v$sql v
       where parsing_schema_name = upper(i_schema_name)
         and substr(v.first_load_time, 1, 10) =
             to_char(sysdate, 'yyyy-mm-dd')
         and (lower(sql_text) not like '%$%' and
             lower(sql_text) not like '%column_name%' and
             lower(sql_text) not like '%dba_%' and
             lower(sql_text) not like '%begin%' and
             lower(sql_text) not like '%explain%' and
             lower(sql_text) not like '%dbms%' and
             lower(sql_text) not like '%object%' and
             lower(sql_text) not like '%parallel%' and
             lower(sql_text) not like '%dbapump%' and
             lower(sql_text) not like '%sys_export%');
  
    cursor cur_table_parts(p_table_name in varchar2) is
      select partition_name
        from user_tab_partitions
       where table_name = p_table_name;
  
    v_sql_text    clob;
    v_table_names t_string_array;
    v_idx         number;
    v_num_rows    number := 100;
    v_blocks      number := 100;
  begin
    for r in cur_sql_plan loop
      dbms_output.enable(50000);
      dbms_output.put_line('======================================== Start ' ||
                           r.first_load_time ||
                           ' ========================================');
    
      v_sql_text := 'explain plan for ' || r.sql_fulltext ||
                    r.sql_fulltext_suppl;
      dbms_output.put_line(v_sql_text);
    
      -- get table name after 'from'
      v_table_names := find_table_name(i_sql_text => v_sql_text,
                                       i_pre      => 'from',
                                       i_pattern  => i_table_prefix);
    
      -- start to evaluate
      begin
        execute immediate v_sql_text;
      
        -- gather statistic
        dbms_output.put_line('>>> gather statistic');
        for s in 1 .. v_table_names.count loop
          v_idx := 0;
          for r_part in cur_table_parts(upper(v_table_names(s))) loop
            v_idx := v_idx + 1;
            dbms_stats.gather_table_stats(ownname          => upper(i_schema_name),
                                          tabname          => upper(v_table_names(s)),
                                          partname         => r_part.partition_name,
                                          estimate_percent => i_estimate_percent);
            dbms_output.put_line('Complete for : Table: ' ||
                                 v_table_names(s) || '- Partition: ' ||
                                 r_part.partition_name);
          
          end loop;
        
          if v_idx = 0 then
          
            dbms_stats.gather_table_stats(ownname          => upper(i_schema_name),
                                          tabname          => upper(v_table_names(s)),
                                          estimate_percent => i_estimate_percent);
            dbms_output.put_line('Complete for : Table: ' ||
                                 v_table_names(s));
          end if;
        end loop;
      
        -- primitive cost
        dbms_output.put_line('----- Primitive Cost -----');
        declare
          cursor cur_display is
            select * from table(dbms_xplan.display(null, null, 'typical'));
        begin
          for l in cur_display loop
            dbms_output.put_line(l.plan_table_output);
          end loop;
        end;
      
        -- magnify statistic
        dbms_output.put_line('>>> magnify statistic');
        for s in 1 .. v_table_names.count loop
          v_idx := 0;
          for r_part in cur_table_parts(upper(v_table_names(s))) loop
            v_idx := v_idx + 1;
          
            select num_rows, blocks
              into v_num_rows, v_blocks
              from user_tab_statistics
             where table_name = upper(v_table_names(s))
               and partition_name = r_part.partition_name;
          
            dbms_stats.set_table_stats(ownname  => upper(i_schema_name),
                                       tabname  => upper(v_table_names(s)),
                                       partname => r_part.partition_name,
                                       numrows  => v_num_rows *
                                                   i_magnify_times,
                                       numblks  => v_blocks *
                                                   i_magnify_times);
            dbms_output.put_line('Complete for : Table: ' ||
                                 v_table_names(s) || '- Partition: ' ||
                                 r_part.partition_name || ' numrows: ' ||
                                 v_num_rows * i_magnify_times ||
                                 ' numblks: ' ||
                                 v_blocks * i_magnify_times);
          end loop;
        
          if v_idx = 0 then
            select num_rows, blocks
              into v_num_rows, v_blocks
              from user_tab_statistics
             where table_name = upper(v_table_names(s));
          
            dbms_stats.set_table_stats(ownname => upper(i_schema_name),
                                       tabname => upper(v_table_names(s)),
                                       numrows => v_num_rows *
                                                  i_magnify_times,
                                       numblks => v_blocks * i_magnify_times);
            dbms_output.put_line('Complete for : Table: ' ||
                                 v_table_names(s) || ' numrows: ' ||
                                 v_num_rows * i_magnify_times ||
                                 ' numblks: ' ||
                                 v_blocks * i_magnify_times);
          end if;
        end loop;
      
        -- stress cost
        dbms_output.put_line('----- Stress Cost -----');
        declare
          cursor cur_display is
            select * from table(dbms_xplan.display(null, null, 'typical'));
        begin
          for l in cur_display loop
            dbms_output.put_line(l.plan_table_output);
          end loop;
        end;
      
        -- restore statistic
        dbms_output.put_line('>>> restore statistic');
        for s in 1 .. v_table_names.count loop
          dbms_stats.restore_table_stats(ownname         => upper(i_schema_name),
                                         tabname         => upper(v_table_names(s)),
                                         as_of_timestamp => sysdate - 1);
          dbms_output.put_line('Complete for : Table: ' ||
                               v_table_names(s));
        end loop;
      exception
        when others then
          dbms_output.put_line(SQLERRM);
      end;
      dbms_output.put_line('======================================== End ========================================');
    end loop;
  
  end find_sql_plan;

  --  ==================================================================
  --  Function: createTokenList
  --
  -- This function takes a string with "tokens" delimited by pDelimiter
  -- and put each "token" into a separate record in a PL/SQL collection. The
  -- PL/SQL collection is returned back to the caller of the function.
  --  ==================================================================
  FUNCTION createTokenList(pLine      IN VARCHAR2,
                                             pDelimiter IN VARCHAR2)
    RETURN t_string_table IS
    sLine     VARCHAR2(2000);
    nPos      INTEGER;
    nPosOld   INTEGER;
    nIndex    INTEGER;
    nLength   INTEGER;
    nCnt      INTEGER;
    sToken    VARCHAR2(200);
    tTokenTab t_string_table;
  BEGIN
    sLine := pLine;
    IF (SUBSTR(sLine, LENGTH(sLine), 1) <> '|') THEN
      sLine := sLine || '|';
    END IF;

    nPos    := 0;
    sToken  := '';
    nLength := LENGTH(sLine);
    nCnt    := 0;

    FOR nIndex IN 1 .. nLength LOOP
      IF ((SUBSTR(sLine, nIndex, 1) = pDelimiter) OR (nIndex = nLength)) THEN
        nPosOld := nPos;
        nPos    := nIndex;
        nCnt    := nCnt + 1;
        sToken  := SUBSTR(sLine, nPosOld + 1, nPos - nPosOld - 1);
      
        tTokenTab(nCnt) := sToken;
      END IF;
    
    END LOOP;

    RETURN tTokenTab;
  END createTokenList;


END common_util;


