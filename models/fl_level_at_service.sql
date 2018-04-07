{{ config(materialized='table') }}

with empty_groups as (
  select *
  from {{ref('fl_empty_groups')}}
  where empty_group_end is not null
), no_camera_blocked as (
  select dumpster_id, org_id, post_timestamp, agg_level
  from {{ref('post_history')}}
  where container_type = 'front load'
  and agg_level is not null
), posts_with_empty_groups as (
  select ncb.*,
  lag(ncb.agg_level) over (partition by ncb.dumpster_id, eg.empty_group_id order by ncb.post_timestamp asc) as "lag_level",
  eg.empty_group_id
  from no_camera_blocked ncb
  left join empty_groups eg
  on (ncb.dumpster_id = eg.dumpster_id
    and ncb.post_timestamp > eg.empty_group_start
    and ncb.post_timestamp <= eg.empty_group_end)
  where eg.empty_group_end is not null
), max_level as (
  select distinct on (dumpster_id, empty_group_id) dumpster_id,
  empty_group_id,
  max(agg_level) over (partition by dumpster_id, empty_group_id) as "max_level"
  from posts_with_empty_groups
  order by dumpster_id, empty_group_id
)
select distinct on (peg.dumpster_id, peg.empty_group_id) peg.dumpster_id,
peg.org_id,
peg.empty_group_id,
peg.post_timestamp,
peg.agg_level as "level_at_service",
peg.lag_level as "level_prior_to_service",
ml.max_level as "max_level_before_service"
from posts_with_empty_groups peg
left join max_level ml
on (peg.dumpster_id = ml.dumpster_id and peg.empty_group_id = ml.empty_group_id)
order by peg.dumpster_id, peg.empty_group_id, peg.post_timestamp desc
