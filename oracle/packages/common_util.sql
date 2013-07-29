CREATE OR REPLACE PACKAGE common_util AS
  PROCEDURE find_sql_plan(i_schema_name IN varchar2);
END common_util;

CREATE OR REPLACE PACKAGE BODY common_util AS

  PROCEDURE find_sql_plan(i_schema_name IN varchar2) is
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
