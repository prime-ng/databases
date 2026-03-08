# Validation Rules
==================

## Calculation based Validation :
--------------------------------

1. Total Weekly required Periods for every Class+Section <= Total Slot Available for that Class+Section
   Total Weekly required Periods = Sum(`sch_class_groups_jnt`.`required_weekly_periods`) Group by `class_id`+`section_id`
   Total Slot Available = File (2-Process_execution.md) Section 1.1

2. Total Peiords Availability of Teachers for a Particuler Class+Subject_Study_format >= Total required Periods for that Class+Subject_Study_format

3. Total No of Rooms in Every Category (Room_type) >= Required Room in that Category (Room_Type)

4. 

5. 



## Timetable Health Checks :
App will validte and showcase Status (If statu = Failed, app suggest required Action)
--------------------------------------------------------------------------------------------------------
### Automatic Check (System will check and showcase Statuss)-
Table - `sch_org_academic_sessions_jnt`
   - Check atleast one record with `flg_single_record` = 1 in `sch_org_academic_sessions_jnt`
Table - `sch_academic_term` & `tt_shift`
   - Check recordcount >= 1 in `sch_academic_term`, `tt_shift`
Table - `sch_class_section_jnt`
   - Check Class_Teacher should be assigned for every record
   - Check `actual_total_student` > 0 in for Every record if NOT then
   - Re-Calculate the Total Student Count `actual_total_student` befor starting Generate Timetable
   - Check `max_allowed_student` > 0 in for Every record if NOT then need to enter mannually.
   - Check `class_house_room_id` # Null for Every Class+Section record
Table - `sch_subject_study_format_jnt`
   - Check if `require_class_house_room` = 1 then `required_room_id` # Null
Table - `sch_class_groups_jnt`
   - 

### Mannual Check (Need to mark True by user before start Generating Timetable)
   (Ask for providng responce as TRUE / FALSE)
   - [ ] Have you configured 'Generation Strategy' ?
   - [ ] Have you Set Timetable Configuration ?

