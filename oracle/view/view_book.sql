create or replace view view_book
as 
select isbn "Book Number",
       name "Name",
       publish_date "Publish Date"
from book;  