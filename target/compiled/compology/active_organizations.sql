

select *
from platform.organization
where is_active
and id not in ('1045bryant', 'comp', 'pingdom', 'riverbend', 'wasteexpo')