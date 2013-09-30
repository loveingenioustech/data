--Dump the current online redo log file.
create or replace procedure dump_log
as
  m_log_name  varchar2(255);
  m_process  varchar2(32);

begin
  select 
    lf.member
  into
    m_log_name
  from
    V$log     lo,
    v$logfile  lf
  where 
    lo.status = 'CURRENT'
  and  lf.group# = lo.group#
  and  rownum = 1
  ;

  execute immediate
  'alter system dump logfile ''' || m_log_name || '''';

  select
    spid
  into
    m_process
  from
    v$session  se,
    v$process  pr
  where
    se.sid = --dbms_support.mysid
      (select sid from v$mystat where rownum = 1)
  and  pr.addr = se.paddr
  ;

  dbms_output.put_line('Trace file name includes: ' || m_process);

end;

create public synonym dump_log for dump_log;

grant execute on dump_log to public;
