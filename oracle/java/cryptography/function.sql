-- build IDEA and IDEAPrepare first
create or replace function encrypt(plainStr varchar2) return varchar2 as
  language java 
  NAME  'IDEA.encrypt(java.lang.String) return java.lang.String'; 
  
create or replace function prepareString(plainStr varchar2) return varchar2 as
  language java 
  NAME  'IDEAPrepare.prepareString(java.lang.String) return java.lang.String';  
  
  
 select prepareString('robin') from dual;
 
 select encrypt(prepareString('robin')) from dual;
 