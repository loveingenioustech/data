select regexp_substr('select streams_pool_size_for_estimate s,           streams_pool_size_factor * 100 f,           estd_spill_time + estd_unspill_time, 0  from study.v$streams_pool_advice where',
                     '\from\W+[a-zA-Z0-9$_.]+\')
  from dual;


select regexp_replace(regexp_substr('select streams_pool_size_for_estimate s,           streams_pool_size_factor * 100 f,           estd_spill_time + estd_unspill_time, 0  from study.v$streams_pool_advice where',
                     '\from\W+[a-zA-Z0-9$_.]+\'), '\from\W\')
  from dual;
  
--tokenize ONE single string  
 DECLARE
   CURSOR cur IS WITH qry AS(
     SELECT 'Paris#London#Rome#Oslo#Amsterdam#New York' city_string
       FROM dual)
     SELECT regexp_substr(city_string, '[^#]+', 1, ROWNUM) city
       FROM qry
     CONNECT BY LEVEL <= LENGTH(regexp_replace(city_string, '[^#]+')) + 1;
 
 BEGIN
   FOR rec IN cur LOOP
     dbms_output.put_line('City:' || rec.city);
   END LOOP;
 END;
   