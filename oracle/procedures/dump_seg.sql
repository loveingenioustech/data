--  =========================================================================
--	Purpose:	Create a procedure to dump blocks from a segment

--	The code is very simple minded with no error trapping.
--	It only covers the first extent (extent zero) of a segment
--	Could be enhanced to use get_ev to save and restore the state 
--	of event 10289 (the one that controls raw/cooked dumps).
--
--  Change in 10.2: the raw block dump always appears in 
--  a block dump, you cannot stop it. Event 10289 blocks
--  the appearance of the formatted dump
--
--  Script has to be run by a DBA who has the privileges to 
--  view v$process, v$session, v$mystat
--
--  Usage
--    the notes assume the tablespace is not ASSM.
--    execute dump_seg('tablex');      -- dump first data block
--    execute dump_seg('tablex',5)      -- dump first five data blocks
--    execute dump_seg('indexy',1,'INDEX')    -- dump root block of index
--    execute dump_seg('tableX',i_start_block=>0 )  -- dump seg header block
--
--  Various "optimizer" issues with 10g:
--    select * from dba_extents 
--    where segment_name = 'T1' 
--    and extent_id = 0;
--  vs.
--    select * from dba_extents 
--    where segment_name = 'T1' 
--    order by extent_id;
--
--  On one system, the first query crashed with error:
--    ORA-00379: no free buffers available in buffer pool DEFAULT for block size 2K
--
--  There had been an object in the 2K tablespace, 
--  which had been dropped but not purged. There 
--  were no buffers allocated to the 2K cache, 
--  hence the failure.  And it was not possible
--  to purge the recyclebin without creating the
--  cache.
--
--  Clearly, the join order had changed because of
--  the extent_id predicate - and this led to the
--  crash
--
--  For this reason, I changed the code to query by
--  segment and order by extent_id - stopping at the
--  zero extent
--
--  Performance can also be affected by how many extents
--  you have, and whether you have collected statistics
--  (in 10g) on the fixed tables - because of the call to
--  check the extents in the segment headers.
--
--  Internal enhancements in 11g
--  You get a dump of all the copies in the buffer cache,
--  and a copy of the version of the block on disc.
--  =========================================================================

create or replace procedure dump_seg(i_seg_name       in varchar2,
                                     i_block_count    in number default 1,
                                     i_seg_type       in varchar2 default 'TABLE',
                                     i_start_block    in number default 1,
                                     i_owner          in varchar2 default sys_context('userenv',
                                                                                      'session_user'),
                                     i_partition_name in varchar2 default null,
                                     i_dump_formatted in boolean default true,
                                     i_dump_raw       in boolean default false) as
  m_file_id   number;
  m_block_min number;
  m_block_max number;
  m_process   varchar2(32);

begin

  for r in (select file_id,
                   block_id + i_start_block block_min,
                   block_id + i_start_block + i_block_count - 1 block_max
              from dba_extents
             where segment_name = upper(i_seg_name)
               and segment_type = upper(i_seg_type)
               and owner = upper(i_owner)
               and nvl(partition_name, 'N/A') =
                   upper(nvl(i_partition_name, 'N/A'))
             order by extent_id) loop
  
    m_file_id   := r.file_id;
    m_block_min := r.block_min;
    m_block_max := r.block_max;
    exit;
  end loop;

  if (i_dump_formatted) then
    execute immediate 'alter session set events ''10289 trace name context off''';
  
    execute immediate 'alter system dump datafile ' || m_file_id ||
                      ' block min ' || m_block_min || ' block max ' ||
                      m_block_max;
  end if;

  if (i_dump_raw) then
    execute immediate 'alter session set events ''10289 trace name context forever''';
  
    execute immediate 'alter system dump datafile ' || m_file_id ||
                      ' block min ' || m_block_min || ' block max ' ||
                      m_block_max;
  
  end if;

  execute immediate 'alter session set events ''10289 trace name context off''';

  --
  --  For non-MTS, work out the trace file name
  --

  select spid
    into m_process
    from v$session se, v$process pr
   where se.sid = (select sid from v$mystat where rownum = 1)
     and pr.addr = se.paddr;

  dbms_output.new_line;
  dbms_output.put_line('Dumped ' || i_block_count || ' blocks from ' ||
                       i_seg_type || ' ' || i_seg_name ||
                       ' starting from block ' || i_start_block);

  dbms_output.new_line;
  dbms_output.put_line('Trace file name includes: ' || m_process);

  dbms_output.new_line;

exception
  when others then
    dbms_output.new_line;
    dbms_output.put_line('Unspecified error.');
    dbms_output.put_line('Check syntax.');
    dbms_output.put_line('dumpseg({segment_name},[{block count}],[{segment_type}]');
    dbms_output.put_line('  [{start block (1)}],[{owner}],[{partition name}]');
    dbms_output.put_line('  [{dump formatted YES/n}],[{dump raw y/NO}]');
    dbms_output.new_line;
    raise;
end;


drop public synonym dump_seg;
create public synonym dump_seg for dump_seg;
grant execute on dump_seg to public;
