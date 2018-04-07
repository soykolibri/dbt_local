

with empty_groups as (
  select ee.dumpster_id,
  d.organization as "org_id",
  lag(ee.occurred_at) over w as "empty_group_start",
  ee.occurred_at as "empty_group_end",
  ee.end_raw_device_data_id,
  row_number() over w as "empty_group",
  ee.updated_at -- placeholder, may want different logic for this later
  from platform.empty_event ee
  inner join platform.dumpster d
  on ee.dumpster_id = d.id
  where ee.was_emptied
  and ee.confidence > 0.5
  window w as (partition by ee.dumpster_id order by ee.occurred_at asc)
)
select dumpster_id,
org_id,
empty_group_start,
empty_group_end,
end_raw_device_data_id,
dumpster_id || '_eg' || empty_group::text as "empty_group_id",
updated_at
from empty_groups
order by 6 desc