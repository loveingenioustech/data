CREATE OR REPLACE PACKAGE common_util AS

  Type t_string_array is table of varchar2(4000);

  -- return pattern matches as array
  -- select * from table(common_util.match('select from event', '\from\'));
  function match(i_str in varchar2, i_pattern in varchar2)
    return t_string_array
    pipelined;

  function find(i_str in clob, i_pattern in varchar2) return t_string_array;

  PROCEDURE find_sql_plan(i_schema_name  IN varchar2,
                          i_table_prefix in varchar2);
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

  PROCEDURE find_sql_plan(i_schema_name  IN varchar2,
                          i_table_prefix in varchar2) is
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
  
    v_sql_text clob;
  begin
    for r in cur_sql_plan loop
      dbms_output.enable(50000);
      dbms_output.put_line('===== Start ' || r.first_load_time || '=====');
      v_sql_text := 'explain plan for ' || r.sql_fulltext ||
                    r.sql_fulltext_suppl;
      dbms_output.put_line(v_sql_text);
      begin
        execute immediate v_sql_text;
      
        declare
          cursor cur_display is
            select * from table(dbms_xplan.display(null, null, 'typical'));
        begin
          for l in cur_display loop
            dbms_output.put_line(l.plan_table_output);
          end loop;
        end;
      exception
        when others then
          dbms_output.put_line(SQLERRM);
      end;
      dbms_output.put_line('===== End =====');
    end loop;
  
  end find_sql_plan;

END common_util;
