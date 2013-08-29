-- Change init parameters
alter system set job_queue_processes = 14;
alter system set java_pool_size = 50m;

-- Create tablespace
create tablespace ts_cdcpub datafile 'ts_cdcpub.dbf' size 100m;

-- Crate user
drop user cdcpub;
CREATE USER cdcpub IDENTIFIED by cdcpub DEFAULT TABLESPACE ts_cdcpub QUOTA UNLIMITED ON SYSTEM QUOTA UNLIMITED ON SYSAUX;

drop user cdcsub;
CREATE USER cdcsub IDENTIFIED by cdcsub DEFAULT TABLESPACE ts_cdcpub;

-- Grant privileges
grant dba to cdcpub;
GRANT CREATE SESSION TO cdcpub;
GRANT CREATE TABLE TO cdcpub;
GRANT CREATE TABLESPACE TO cdcpub;
GRANT CREATE JOB TO cdcpub;
GRANT UNLIMITED TABLESPACE TO cdcpub;
GRANT SELECT_CATALOG_ROLE TO cdcpub;
GRANT EXECUTE_CATALOG_ROLE TO cdcpub;
GRANT ALL ON sh.sales TO cdcpub;
GRANT ALL ON sh.products TO cdcpub;
GRANT EXECUTE ON DBMS_CDC_PUBLISH TO cdcpub;

grant dba to cdcsub;

grant select on all_change_sets to cdcpub;
grant select on all_change_tables to cdcpub;

grant execute on dbms_lock to cdcpub;
grant execute on dbms_lock to cdcsub;