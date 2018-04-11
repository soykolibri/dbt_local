{{ config(materialized='table') }}

with routes as (
  select r.id,
  r.organization_id,
  r.created_at,
  r.started_at,
  r.completed_at,
  r.content_type,
  r.added_fuel_gallons as "fuel_gallons",
  r.miles_driven,
  us.full_name as "driver"
  from platform.route r
  left join platform.user us
  on r.assigned_to_id = us.id
  where exists(select 1 from {{ref('active_organizations')}} where us.organization = id)
), route_tasks as (
  select rt.id as "route_task_id",
  rt.task_id,
  rt.route_id,
  rt.started_at,
  rt.resolved_at,
  rt.resolution,
  rt.skip_reason,
  extract(epoch from rt.resolved_at - rt.created_at)::numeric/3600/24 as "days_to_resolve_route_task"
  from platform.route_task rt
  where exists(select 1 from routes r where rt.route_id = r.id)
)
select rs.started_at as "route_started_at",
rs.organization_id as "org_id",
t.dumpster_id,
rts.started_at as "route_task_started_at",
t.action_type,
t.dumpster_cubic_yards,
t.description as "task_description",
rts.resolution,
rts.resolved_at as "route_task_resolved_at",
rts.days_to_resolve_route_task,
rts.skip_reason,
rs.driver,
rs.content_type,
rs.fuel_gallons,
rs.miles_driven,
rts.route_task_id,
rts.route_id,
rs.completed_at as "route_completed_at",
rts.task_id,
t.created_at as "task_created_at",
t.deleted_at as "task_deleted_at",
t.resolved_at as "task_resolved_at"
from route_tasks rts
left join platform.task t
on rts.task_id = t.id
left join routes rs
on rts.route_id = rs.id
where (t.deleted_at is null or t.deleted_at > rts.resolved_at)
and rts.resolution != 'unassign'
order by rs.started_at desc, rts.started_at asc, rs.organization_id asc
