create or replace procedure getEmployeeInfo(employeeName in varchar2,
                                            employeeInfo out SYS_REFCURSOR) is
begin
  open employeeInfo for
    select e.id, e.name, e.salary, e.update_user_id, e.update_time
      from employee e
     where e.name = employeeName;

end;
