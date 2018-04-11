
  
    
  

  
    
  create view "dbt_clarice"."completed_route_tasks__dbt_tmp" as (
    

with containers as (
  select id, description
  from platform.dumpster
  where organization = 'pssi'
  and lower(description) not similar to '%(compactor|no sensor)%'
), route_history as (
  select * from "dbt_clarice"."route_history"
  where org_id = 'pssi'
  and resolution = 'complete'
  and exists(select 1 from containers c where dumpster_id = c.id)
  and task_description not ilike '%compactor%'
)
select rh.task_id,
rh.route_task_resolved_at as "task_completed_at",
rh.dumpster_id,
rh.task_description,
count(lt.id) as "landfill_tickets",
array_agg(distinct lt.location_id) as "landfill_loc_id"
from route_history rh
left join platform.landfill_ticket lt
on rh.task_id = lt.task_id
group by 1, 2, 3, 4
order by 2 desc
  );