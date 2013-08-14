create or replace view view_event
as 
select id "Event ID",
       title "Title",
       title# "Title Backup",
       start_date "Start Date"
from event;