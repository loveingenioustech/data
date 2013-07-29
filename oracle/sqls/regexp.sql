select regexp_substr('select streams_pool_size_for_estimate s,           streams_pool_size_factor * 100 f,           estd_spill_time + estd_unspill_time, 0  from study.v$streams_pool_advice where',
                     '\from\W+[a-zA-Z0-9$_.]+\')
  from dual;


select regexp_replace(regexp_substr('select streams_pool_size_for_estimate s,           streams_pool_size_factor * 100 f,           estd_spill_time + estd_unspill_time, 0  from study.v$streams_pool_advice where',
                     '\from\W+[a-zA-Z0-9$_.]+\'), '\from\W\')
  from dual;