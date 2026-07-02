# Requirement Conditions Catalog — TimetableFoundation (TTF)
**Module:** TimetableFoundation | **Code:** TTF
**Date:** 2026-06-30 | **Source:** `TTF_FRD_Complete_2026-06-30.md` §3.2
**BR IDs defined in:** `TTF_FRD_2026-06-30.md` §4

> This file is the canonical location for TTF business rule conditions.
> Full rule definitions, enforcement status, and gap analysis are in the Complete Analysis Pack.

| Condition ID | Entity / Field | Condition (business language) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-TTF-001 | Period Slot / End Time | End Time must be later than Start Time | Validation | Store/Update Period Slot | Reject: "End time must be after start time" |
| BR-TTF-002 | Timetable Type / School Times | School start/end times for same Shift must not overlap with another Timetable Type | Validation | Store/Update Timetable Type | Reject: "Times overlap with [name]" |
| BR-TTF-003 | Period Slot / Period Duration | Period Duration is database-computed; application must never write this field | Calculation | Eloquent save on PeriodSetPeriod | Field must be absent from $fillable |
| BR-TTF-004a | Class-Timetable-Type / applies_to_all_sections | If "Applies to All Sections" is true, no section may be selected | Validation | Store/Update Class-Timetable-Type | Reject: "Select either all sections or a specific section" |
| BR-TTF-004b | Class-Timetable-Type / section_id | If a specific section is selected, "Applies to All Sections" must be false | Validation | Store/Update Class-Timetable-Type | Same as BR-TTF-004a |
| BR-TTF-005 | Academic Term / Date Range | Terms within the same academic session must not have overlapping start/end dates | Validation | Store/Update Academic Term | Reject: "Term dates overlap with [Term Name] ([date range])" |
| BR-TTF-006 | Activity | One activity per class-section-subject-study-format combination per academic term | Validation | Store Activity / Generate Activities | Reject or skip duplicate; log skipped items |
| BR-TTF-007 | Teacher Availability / available_for_full_timetable_duration | Database-computed field; application must never write this | Calculation | Eloquent save on TeacherAvailability | Field must be absent from $fillable |
| BR-TTF-008 | Teacher Availability / no_of_days_not_available | Database-computed field; application must never write this | Calculation | Eloquent save on TeacherAvailability | Field must be absent from $fillable |
| BR-TTF-009 | Period Set / is_default | Only one Period Set may carry the default flag | Validation | Toggle Period Set default | Clear previous default before setting new one |
| BR-TTF-010 | Teacher Availability Detail / slot key | (teacher_profile_id, day_number, period_number) must be unique | Validation | Store Teacher Availability Detail | Catch DB unique violation; return "Slot already configured — update instead of creating" |
| BR-TTF-011a | Timetable Config / tenant_can_modify | System-managed config keys (tenant_can_modify = false) cannot be updated by school users | Permission | Inline config edit | Reject with 403 Forbidden |
| BR-TTF-012 | Generation Strategy / is_default | Only one generation strategy may be the default | Validation | Toggle Generation Strategy default | Unset current default then set new one in a single transaction |
| BR-TTF-013 | Requirement Consolidation / uniqueness | No duplicate consolidation record per class-section-subject-format-term | Validation | Generate Requirements | Skip duplicates; log count in response |
| BR-TTF-014a | Shift / code | Shift code must be unique across the school | Validation | Store/Update Shift | Catch DB unique violation; return "Shift code already exists" |
| BR-TTF-014b | Shift / name | Shift name must be unique across the school | Validation | Store/Update Shift | Catch DB unique violation; return "Shift name already exists" |
| BR-TTF-014c | Shift / ordinal | Shift display order must be unique | Validation | Store/Update Shift | Catch DB unique violation; return "Display order already in use" |
| BR-TTF-015 | Working Day / day_type_id | When Day Type changes, Academic Term teaching/exam/working day counters must be recalculated | Workflow | AJAX edit Working Day | Observer fires; term counters updated atomically — NOT YET IMPLEMENTED |
