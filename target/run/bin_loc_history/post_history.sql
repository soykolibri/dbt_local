
  
    
  

  
    
  create  table
    "dbt_clarice"."post_history__dbt_tmp" as (
    

select rdd.id as "raw_device_data_id",
d.organization as "org_id",
rdd.dumpster_id,
d.container_type,
d.dumpster_timezone,
rdd.post_timestamp,
rdd.agg_camera_blocked,
rdd.agg_level,
l.id as "location_id",
l.description as "location_name",
l.type as "location_type",
da.is_active,
rdd.lat,
rdd.lon,
case when rdd.latlon_radius in (0, 70000) then null else rdd.latlon_radius end as "latlon_radius",
case when rdd.latlon_radius < 50 and rdd.latlon_radius != 0 then 1 else 0 end as "good_gps",
firmware,
case
  when firmware like 'oscar-00%' or firmware = 'oscar-lte2' then 'R10'
  when firmware like 'oscar-_1%' then 'R11'
  when firmware like 'oscar-_2%' then 'R12'
  else null end as "sensor_model",
case
  when (rdd.extra_info::json ->> 'wake_reason') = '0' then 'unknown'
  when (rdd.extra_info::json ->> 'wake_reason') = '1' then 'scheduled post'
  when (rdd.extra_info::json ->> 'wake_reason') = '2' then 'accelerometer trigger'
  when (rdd.extra_info::json ->> 'wake_reason') = '3' then 'FW/HW issue'
  when (rdd.extra_info::json ->> 'wake_reason') = '4' then 'power issue'
  when (rdd.extra_info::json ->> 'wake_reason') = '5' then 'reset after programming'
  else null end as "wake_reason",
case
  when rdd.extra_info::json ->> 'accel_int' is null then null
  when rdd.extra_info::json ->> 'accel_int' = 'true' then true
  else false end as "accel_int",
(rdd.extra_info::json ->> 'signal_dbi')::int as "signal_dbi",
(rdd.extra_info::json ->> 'consecutive_failed_wakes')::int as "consecutive_failed_wakes",
(rdd.extra_info::json ->> 'session_count')::int as "session_count",
rdd.errors::text as "errors"
from platform.raw_device_data rdd
inner join platform.dumpster d
on rdd.dumpster_id = d.id
left join platform.dumpster_arrival da
on rdd.id = da.raw_device_data_id
left join platform.location l
on da.location_id = l.id
where not d.is_hidden
and not d.is_hidden_for_org
and not rdd.in_maintenance_mode
  );