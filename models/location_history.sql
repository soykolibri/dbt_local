{{ config(materialized='table') }}

select dumpster_id,
location_id,
arrived_at,
lead(arrived_at) over w as "departed_at"
from platform.dumpster_arrival
where is_active
window w as (partition by dumpster_id order by arrived_at asc)
