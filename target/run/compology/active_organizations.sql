
  
    
  

  
    
  create view "dbt_clarice"."active_organizations__dbt_tmp" as (
    

select *
from platform.organization
where is_active
and id not in ('1045bryant', 'comp', 'pingdom', 'riverbend', 'wasteexpo')
  );