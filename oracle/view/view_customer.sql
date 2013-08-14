create or replace view view_customer
as 
select customer_id "Customer ID",
       first_name "First Name",
       last_name "Last Name",
       born_date "Born Date"
from customer;    