# Conditions & Parameters needs to implement into App
=====================================================


### What should NOT consider for Prioritisation
-----------------------------------------------
Below fields should not be considered for Allocation Prioritisation:

| `is_compulsory` | USER_PROVIDED bool | tt_activity.is_compulsory | 
| `min_periods_per_week` | USER_PROVIDED int | tt_activity.min_periods_per_week | 
| `max_periods_per_week` | USER_PROVIDED int | tt_activity.max_periods_per_week | 
| `min_per_day` | USER_PROVIDED int | tt_activity.min_per_day | 
| `max_per_day` | USER_PROVIDED int | tt_activity.max_per_day |








### What SHOULD BE considered for Prioritisation
------------------------------------------------
Below fields Must be considered for Allocation Prioritisation:

| `difficulty_score` | USER_PROVIDED 0–100 | tt_activity.difficulty_score | This 
| `difficulty_score_calculated` | COMPUTED 0–100 | tt_activity.difficulty_score_calculated |
| `preferred_periods_json` | USER_PROVIDED int[] | tt_activity.preferred_periods_json |
| `avoid_periods_json` | USER_PROVIDED int[] | tt_activity.avoid_periods_json |
| `preferred_time_slots_json` | USER_PROVIDED [{day,period_ord},…] | tt_activity.preferred_time_slots_json |
| `avoid_time_slots_json` | USER_PROVIDED [{day,period_ord},…] | tt_activity.avoid_time_slots_json |




### Conditions (Must be followed by Algo)
-----------------------------------------
Class Teacher Conditions :
- 1st Period of Every Class will be taken by Class Teacher. Below condition needs to be checked before assigning.
- If Class Teacher doesn't teach any subject for the class which is assigned her as a Class Teacher then any Teacher can be assigned 1st Period.
- If Total Required Periods of the Subject which can be tought by class teacher


Validation Check :
- If a Class Teacher is not having any Teaching capability to teach any subject of the class for which she is assigned as a Class Teach, then Raise Flag
- 

| A20 | `spread_evenly` | USER_PROVIDED bool | tt_activity.spread_evenly | Yes (+10 / −15) | Day-balance preference |
| A21 | `split_allowed` | USER_PROVIDED bool | tt_activity.split_allowed | Yes (−100 if violated) | Multi-day split permitted |

