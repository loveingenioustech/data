CREATE OR REPLACE PROCEDURE generate_data_for_item(i_schema_name  in varchar2,
                                        i_table_name   in varchar2,
                                        i_record_count in integer,
                                        i_options      in varchar2) is
-- Define collection types and variables
TYPE row_num_type IS
  TABLE OF NUMBER INDEX BY PLS_INTEGER;
  TYPE row_text_type IS TABLE OF VARCHAR2(200) INDEX BY PLS_INTEGER;

  row_num_tab_id         row_num_type;
  row_num_tab_im_id      row_num_type;
  row_text_tab_name      row_text_type;
  row_num_tab_price      row_num_type;
  row_text_tab_data      row_text_type;  

  v_total NUMBER;

begin
  dbms_output.enable(500000);
  dbms_output.put_line('======================================== Start ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

  -- Populate collections
  DBMS_RANDOM.INITIALIZE(TO_NUMBER (TO_CHAR (SYSDATE, 'SSSSS') ) );
  
  FOR i IN 1 .. i_record_count LOOP
    --row_num_tab_id(i) := trunc(dbms_random.value(1,101));
    row_num_tab_id(i)    := i;
    row_num_tab_im_id(i) := (1+ABS(MOD(dbms_random.random,1000000)));        
    row_text_tab_name(i) := dbms_random.string('A', 5);
    row_num_tab_price(i) := trunc(dbms_random.value(1,1000), 2);        
    row_text_tab_data(i) := dbms_random.string('P', 50);

  END LOOP;
  
  DBMS_RANDOM.TERMINATE;

  -- Populate item table
  -- e.g. insert into item (i_id, i_im_id, i_name, i_price, i_data) values (1, 2, 'Test', 0.5, 'Test Data')

  FORALL i IN 1 .. i_record_count
         
    INSERT INTO item
      (i_id, i_im_id, i_name, i_price, i_data)
    VALUES
      (row_num_tab_id(i), row_num_tab_im_id(i), row_text_tab_name(i), row_num_tab_price(i), row_text_tab_data(i));
  COMMIT;

  -- Check how many rows were inserted in the TEST table
  -- and display it on the screen
  SELECT COUNT(*) INTO v_total FROM item;
  DBMS_OUTPUT.PUT_LINE('There are ' || v_total ||
                       ' rows in the ITEM table');

  dbms_output.put_line('======================================== End ' ||
                       to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') ||
                       ' ========================================');

exception
  when others then
    dbms_output.put_line(SQLERRM);
end generate_data_for_item;
