select /* recentsql */
 sql_id, child_number, hash_value, address, executions, sql_text
  from v$sql
 where parsing_user_id =
       (select user_id from all_users where username = 'STUDY')
   and command_type in (2, 3, 6, 7, 189)
   and UPPER(sql_text) not like UPPER('%recentsql%');
   
   
select /*+ gather_plan_statistics */
 a.employee_id, a.first_name, a.last_name
  from employees a
 where a.last_name = 'King';

select *
  from table(dbms_xplan.display_cursor(null, null, 'ALLSTATS LAST'));


SELECT xplan.*
 FROM (select max(sql_id) keep(dense_rank last order by last_active_time) sql_id,
              max(child_number) keep(dense_rank last order by last_active_time) child_number
         from v$sql
        where upper(sql_text) like '%&1%'
          and upper(sql_text) not like
              '%FROM V$SQL WHERE UPPER(SQL_TEXT) LIKE %') sqlinfo,
      table(DBMS_XPLAN.DISPLAY_CURSOR(sqlinfo.sql_id,
                                      sqlinfo.child_number,
                                      'typical')) xplan;


select 'Analyze table '||table_name||' compute statistics;'
from user_tables;

Analyze table EMPLOYEES compute statistics;


