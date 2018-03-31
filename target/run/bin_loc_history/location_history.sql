
  
    
  

  
    
  create view "dbt_clarice"."location_history__dbt_tmp" as (
    

select dumpster_id, arrived_at, is_active
from platform.dumpster_arrival
where is_active
  );