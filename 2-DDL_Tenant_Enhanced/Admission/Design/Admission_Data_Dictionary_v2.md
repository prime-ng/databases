# Prime-AI Admission Management Module — Data Dictionary

**Document ID:** ADM-DD-V2.0  
**Version:** 2.0  
**Date:** 2026-09-23  
**Describes:** `Admission_DDL_v2.sql` — 20 tables across 9 layers  
**Database:** `tenant_db` (One database per school tenant · MySQL 8.0.16+ · InnoDB · utf8mb4)  
**Table Prefix:** `adm_*`  
**Governed by:** `Admission_BRD_v2.md` (What the business needs) · `Admission_Solution_Design_v2.md` (How it works)  
**Companion Document:** `Admission_Process_Flow_v2.md` (Screens & operational workflows)  

---

## How to Read This Dictionary

Every table specification contains four structural sections:

| Section | What It Explains |
|---|---|
| **1. Purpose & Business Context** | Plain-English summary of what business process the table serves and its operational invariants. |
| **2. Example Data Row** | A realistic, fully hydrated data row illustrating table shape and representative field values. |
| **3. Column Specification** | Complete column attributes: physical type, nullability, key indicator, functional description, business constraints, and example value. |
| **4. Keys, Indexes & Foreign Constraints** | Primary keys, composite unique constraints, performance indexes, and cascade update/delete behavior. |

### Notation & Symbols

| Notation | Meaning |
|---|---|
| **PK** | Primary Key (auto-incrementing identifier). |
| **UK** | Unique Key (or composite unique key enforcing a business uniqueness rule). |
| **FK** | Foreign Key (references a specified parent table). |
| **GEN** | Generated / Virtual column calculated automatically by MySQL. |
| **FROZEN** | Value snapshotted at a specific moment in time; never dynamically re-read from master. |
| **CACHE** | Operational counter or cached calculation maintained by a service; rebuildable. |
| **✔ / —** | Column permits NULL (`✔`) or is strictly NOT NULL (`—`). |

---

## Universal Patterns Used Throughout the Schema

### 1. Audit & Soft-Delete Columns
Every table carries standard operational timestamps and audit columns:

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `created_at` | `TIMESTAMP` | ✔ | Timestamp when record was initially created. | `2026-03-27 10:15:30` |
| `updated_at` | `TIMESTAMP` | ✔ | Timestamp when record was last updated. | `2026-03-28 14:22:00` |
| `deleted_at` | `TIMESTAMP` | ✔ | Soft-delete timestamp; `NULL` = active record. | `NULL` |
| `is_active` | `TINYINT(1)` | — | Soft enable/disable flag (`1` = active, `0` = disabled). | `1` |

### 2. Tenant Isolation Invariant
All 20 tables reside exclusively in the school's dedicated tenant database (`tenant_db`). No `tenant_id` column exists on any table, eliminating multi-tenant data leakage risks at the physical schema level.

---

## Table Inventory by Architectural Layer

```
Layer 1: adm_admission_cycles (1 table)
Layer 2: adm_document_checklist · adm_quota_config · adm_seat_capacity · adm_entrance_tests (4 tables)
Layer 3: adm_enquiries · adm_merit_lists (2 tables)
Layer 4: adm_follow_ups · adm_applications (2 tables)
Layer 5: adm_application_documents · adm_application_stages_log · adm_entrance_test_candidates · adm_merit_list_entries (4 tables)
Layer 6: adm_allotments · adm_promotion_batches (2 tables)
Layer 7: adm_withdrawals · adm_promotion_records (2 tables)
Layer 8: adm_transfer_certificates · adm_behavior_incidents (2 tables)
Layer 9: adm_behavior_actions (1 table)
Total: 20 Tables
```

---

## LAYER 1: Core Configuration Master

### 1. `adm_admission_cycles`

#### Purpose & Business Context
Governs the annual admission cycle configuration for an academic year. Controls application date windows, public portal slugs, application fees, age rules, refund policies, and admission numbering formats. Exactly one cycle can be active per academic session.

#### Example Row
```json
{
  "id": 1,
  "academic_session_id": 4,
  "name": "Main Admission 2026-27",
  "cycle_code": "ADM-2627-M",
  "start_date": "2026-01-15",
  "end_date": "2026-03-31",
  "application_fee": 1500.00,
  "admission_no_format": "DPS/{YEAR}/{SEQ}",
  "sibling_bonus_score": 5,
  "age_cut_off_date": "2026-12-31",
  "age_rules_json": "{\"1\":{\"min\":5,\"max\":7},\"2\":{\"min\":6,\"max\":8}}",
  "refund_policy_json": "{\"7\":100,\"15\":80,\"30\":50,\"999\":0}",
  "application_form_url": "admission-2026-27",
  "status": "Open",
  "is_active": 1,
  "active_flag": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `SMALLINT UNSIGNED` | — | **PK** | Primary key. | `1` |
| `academic_session_id` | `SMALLINT UNSIGNED` | — | **FK, UK** | Target academic session (`sch_org_academic_sessions_jnt.id`). | `4` |
| `name` | `VARCHAR(100)` | — | | Institutional cycle name. | `Main Admission 2026-27` |
| `cycle_code` | `VARCHAR(20)` | — | **UK** | Unique cycle code identifier. | `ADM-2627-M` |
| `start_date` | `DATE` | — | | Public enquiry/application opening date. | `2026-01-15` |
| `end_date` | `DATE` | — | | Closing date; must be strictly $> \text{start\_date}$. | `2026-03-31` |
| `application_fee` | `DECIMAL(10,2)` | — | | Application processing fee in INR (default `0.00`). | `1500.00` |
| `admission_no_format` | `VARCHAR(100)` | ✔ | | Pattern for student IDs (default `{YEAR}/{SEQ}`). | `DPS/{YEAR}/{SEQ}` |
| `sibling_bonus_score` | `TINYINT UNSIGNED` | — | | Merit bonus score for confirmed siblings (0–100). | `5` |
| `age_cut_off_date` | `DATE` | — | | Statutory age calculation cut-off date. | `2026-12-31` |
| `age_rules_json` | `JSON` | ✔ | | Min/max allowed age in years per class ID. | `{"1":{"min":5,"max":7}}` |
| `refund_policy_json` | `JSON` | ✔ | | Piecewise refund % tiers based on days elapsed. | `{"7":100,"30":50}` |
| `application_form_url` | `VARCHAR(255)` | ✔ | | Public URL slug used in `/apply/{slug}`. | `admission-2026-27` |
| `status` | `ENUM` | — | | Lifecycle: `Draft`, `Open`, `Closed`, `Archived`. | `Open` |
| `is_active` | `TINYINT(1)` | — | **UK** | Soft enable/disable flag. | `1` |
| `active_flag` | `TINYINT(1)` | — | | Set to 1 when `status = 'Open'` and `is_active = 1`. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `UNIQUE KEY uq_adm_cyc_code (cycle_code)`
- `UNIQUE KEY uq_adm_cyc_active (academic_session_id, is_active)`
- `FOREIGN KEY (academic_session_id) REFERENCES sch_org_academic_sessions_jnt (id) ON DELETE RESTRICT ON UPDATE CASCADE`

---

## LAYER 2: Admission Setup & Quota Masters

### 2. `adm_document_checklist`

#### Purpose & Business Context
Defines mandatory and optional KYC document requirements per cycle and class. Global default templates carry `admission_cycle_id = NULL` and `is_system = 1`.

#### Example Row
```json
{
  "id": 10,
  "admission_cycle_id": 1,
  "class_id": 1,
  "document_name": "Birth Certificate",
  "document_code": "BIRTH_CERT",
  "is_mandatory": 1,
  "is_system": 0,
  "accepted_formats": "pdf,jpg,png",
  "max_size_kb": 5120,
  "sort_order": 1,
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `MEDIUMINT UNSIGNED` | — | **PK** | Primary key. | `10` |
| `admission_cycle_id` | `SMALLINT UNSIGNED` | ✔ | **FK** | Linked cycle; `NULL` = global system template. | `1` |
| `class_id` | `INT UNSIGNED` | ✔ | **FK** | Target class (`sch_classes.id`); `NULL` = all classes. | `1` |
| `document_name` | `VARCHAR(100)` | — | | Display label for document requirement. | `Birth Certificate` |
| `document_code` | `VARCHAR(30)` | — | | Programmatic identifier. | `BIRTH_CERT` |
| `is_mandatory` | `TINYINT(1)` | — | | `1` = verification required before shortlist. | `1` |
| `is_system` | `TINYINT(1)` | — | | `1` = seeded system template; `0` = school created. | `0` |
| `accepted_formats` | `VARCHAR(100)` | — | | Comma-separated file extensions. | `pdf,jpg,png` |
| `max_size_kb` | `INT UNSIGNED` | — | | Maximum upload size in KB (default `5120`). | `5120` |
| `sort_order` | `TINYINT UNSIGNED` | — | | UI presentation sequence. | `1` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_chk_cycle (admission_cycle_id)`
- `KEY idx_adm_chk_class (class_id)`
- `FOREIGN KEY (admission_cycle_id) REFERENCES adm_admission_cycles (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (class_id) REFERENCES sch_classes (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

### 3. `adm_quota_config`

#### Purpose & Business Context
Configures seat quota policies (General, Management, RTE, NRI, EWS, etc.) per class, specifying statutory reservation minimums and application fee waiver privileges.

#### Example Row
```json
{
  "id": 5,
  "admission_cycle_id": 1,
  "class_id": 1,
  "quota_type": "RTE",
  "total_seats": 25,
  "reserved_seats": 25,
  "application_fee_waiver": 1,
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `SMALLINT UNSIGNED` | — | **PK** | Primary key. | `5` |
| `admission_cycle_id` | `SMALLINT UNSIGNED` | — | **FK** | Associated cycle. | `1` |
| `class_id` | `INT UNSIGNED` | — | **FK** | Associated class. | `1` |
| `quota_type` | `ENUM` | — | **KEY** | `General`, `Government`, `Management`, `RTE`, `NRI`, `Staff_Ward`, `Sibling`, `EWS`. | `RTE` |
| `total_seats` | `SMALLINT UNSIGNED` | — | | Total seats assigned to this quota category. | `25` |
| `reserved_seats` | `SMALLINT UNSIGNED` | — | | Mandated statutory minimum (e.g., 25% RTE). | `25` |
| `application_fee_waiver` | `TINYINT(1)` | — | | `1` = waive application fee at portal. | `1` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_qcfg_cycle_class (admission_cycle_id, class_id)`
- `KEY idx_adm_qcfg_quota (quota_type)`
- `FOREIGN KEY (admission_cycle_id) REFERENCES adm_admission_cycles (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (class_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`

---

### 4. `adm_seat_capacity`

#### Purpose & Business Context
Maintains real-time seat budget counters (`total_seats`, `seats_allotted`, `seats_enrolled`) per cycle, class, and quota. Guarantees that allotments never exceed authorized seat allocations.

#### Example Row
```json
{
  "id": 12,
  "admission_cycle_id": 1,
  "class_id": 1,
  "quota_type": "General",
  "total_seats": 60,
  "seats_allotted": 45,
  "seats_enrolled": 38,
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `SMALLINT UNSIGNED` | — | **PK** | Primary key. | `12` |
| `admission_cycle_id` | `SMALLINT UNSIGNED` | — | **FK, UK** | Associated cycle. | `1` |
| `class_id` | `INT UNSIGNED` | — | **FK, UK** | Associated class. | `1` |
| `quota_type` | `ENUM` | — | **UK** | Category quota type. | `General` |
| `total_seats` | `SMALLINT UNSIGNED` | — | | Budgeted seat limit. | `60` |
| `seats_allotted` | `SMALLINT UNSIGNED` | — | **CACHE** | Running counter of provisional seat offers. | `45` |
| `seats_enrolled` | `SMALLINT UNSIGNED` | — | **CACHE** | Running counter of fully enrolled students. | `38` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `UNIQUE KEY uq_adm_sc_cycle_class_quota (admission_cycle_id, class_id, quota_type)`
- `FOREIGN KEY (admission_cycle_id) REFERENCES adm_admission_cycles (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (class_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`

---

### 5. `adm_entrance_tests`

#### Purpose & Business Context
Schedules entrance and aptitude test sessions by class and cycle. Supports both offline (venue + uploaded paper) and online (CBT portal link) testing formats. Enforces NEP 2020 screening prohibition on foundational classes.

#### Example Row
```json
{
  "id": 3,
  "admission_cycle_id": 1,
  "class_id": 5,
  "test_name": "Class 5 Aptitude Assessment",
  "test_date": "2026-02-20",
  "start_time": "10:00:00",
  "end_time": "12:00:00",
  "venue": "Campus Auditorium / Hall A",
  "test_type": "Offline",
  "online_test_link": null,
  "offline_test_media_id": 84,
  "max_marks": 100.00,
  "passing_marks": 40.00,
  "subjects_json": "[{\"name\":\"Maths\",\"max\":50},{\"name\":\"English\",\"max\":50}]",
  "status": "Scheduled",
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `MEDIUMINT UNSIGNED` | — | **PK** | Primary key. | `3` |
| `admission_cycle_id` | `SMALLINT UNSIGNED` | — | **FK** | Associated cycle. | `1` |
| `class_id` | `INT UNSIGNED` | — | **FK** | Target class (Warning/Block if class ordinal $\le 2$). | `5` |
| `test_name` | `VARCHAR(100)` | — | | Test session name. | `Class 5 Aptitude Assessment` |
| `test_date` | `DATE` | — | **KEY** | Date of examination. | `2026-02-20` |
| `start_time` | `TIME` | — | | Start time; must be $< \text{end\_time}$. | `10:00:00` |
| `end_time` | `TIME` | — | | End time. | `12:00:00` |
| `venue` | `VARCHAR(100)` | ✔ | | Physical campus room or location. | `Campus Auditorium / Hall A` |
| `test_type` | `ENUM` | — | | Delivery mode: `Online`, `Offline`. | `Offline` |
| `online_test_link` | `VARCHAR(255)` | ✔ | | Virtual examination portal URL. | `NULL` |
| `offline_test_media_id` | `INT UNSIGNED` | ✔ | **FK** | FK to `sys_media.id` for question paper PDF. | `84` |
| `max_marks` | `DECIMAL(6,2)` | — | | Maximum possible test score. | `100.00` |
| `passing_marks` | `DECIMAL(6,2)` | ✔ | | Minimum pass mark threshold (`NULL` = no cutoff). | `40.00` |
| `subjects_json` | `JSON` | ✔ | | Subject-wise maximum marks breakdown. | `[{"name":"Maths","max":50}]` |
| `status` | `ENUM` | — | **KEY** | Lifecycle: `Scheduled`, `Completed`, `Cancelled`. | `Scheduled` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_et_cycle_class (admission_cycle_id, class_id)`
- `KEY idx_adm_et_date (test_date)`
- `KEY idx_adm_et_status (status)`
- `FOREIGN KEY (admission_cycle_id) REFERENCES adm_admission_cycles (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (class_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`

---

## LAYER 3: Lead CRM & Merit Headers

### 6. `adm_enquiries`

#### Purpose & Business Context
Captures raw leads across digital and walk-in channels. Executes automated sibling phone matching against `std_guardians.mobile_no` and flags duplicate inquiries within the cycle.

#### Example Row
```json
{
  "id": 105,
  "admission_cycle_id": 1,
  "enquiry_no": "ENQ-2026-00105",
  "student_name": "Aarav Sharma",
  "student_dob": "2020-05-14",
  "student_gender": "Male",
  "class_sought_id": 1,
  "father_name": "Vikram Sharma",
  "mother_name": "Neha Sharma",
  "contact_name": "Vikram Sharma",
  "contact_mobile": "9876543210",
  "contact_email": "vikram.sharma@example.com",
  "lead_source": "Website",
  "status": "Assigned",
  "counselor_id": 14,
  "is_sibling_lead": 1,
  "sibling_student_id": 42,
  "is_duplicate": 0,
  "notes": "Parent interested in school transport and day boarding.",
  "source_reference": "GOOGLE_SEARCH_CAMP_26",
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `MEDIUMINT UNSIGNED` | — | **PK** | Primary key. | `105` |
| `admission_cycle_id` | `SMALLINT UNSIGNED` | — | **FK** | Associated cycle. | `1` |
| `enquiry_no` | `VARCHAR(20)` | — | **UK** | Auto-generated number (`ENQ-YYYY-NNNNN`). | `ENQ-2026-00105` |
| `student_name` | `VARCHAR(100)` | — | | Prospective student's full name. | `Aarav Sharma` |
| `student_dob` | `DATE` | ✔ | | Date of birth for age eligibility checking. | `2020-05-14` |
| `student_gender` | `ENUM` | ✔ | | `Male`, `Female`, `Transgender`, `Other`. | `Male` |
| `class_sought_id` | `INT UNSIGNED` | — | **FK** | Class applied for (`sch_classes.id`). | `1` |
| `father_name` | `VARCHAR(100)` | ✔ | | Father name. | `Vikram Sharma` |
| `mother_name` | `VARCHAR(100)` | ✔ | | Mother name. | `Neha Sharma` |
| `contact_name` | `VARCHAR(100)` | — | | Primary parent or guardian contact name. | `Vikram Sharma` |
| `contact_mobile` | `VARCHAR(15)` | — | **KEY** | Primary mobile (matched for siblings). | `9876543210` |
| `contact_email` | `VARCHAR(100)` | ✔ | | Primary contact email. | `vikram.sharma@example.com` |
| `lead_source` | `ENUM` | — | | `Website`, `Walk-in`, `Campaign`, `Referral`, `Social_Media`, `Phone`, `Other`. | `Website` |
| `status` | `ENUM` | — | **KEY** | `New`, `Assigned`, `Contacted`, `Interested`, `Not_Interested`, `Callback`, `Converted`, `Duplicate`. | `Assigned` |
| `counselor_id` | `INT UNSIGNED` | ✔ | **FK** | Assigned admission counselor (`sys_users.id`). | `14` |
| `is_sibling_lead` | `TINYINT(1)` | — | | `1` = auto-detected sibling match. | `1` |
| `sibling_student_id` | `INT UNSIGNED` | ✔ | **FK** | Matched existing student (`std_students.id`). | `42` |
| `is_duplicate` | `TINYINT(1)` | — | | `1` = duplicate mobile in same cycle. | `0` |
| `notes` | `TEXT` | ✔ | | Free-text notes from counselor. | `Parent interested in...` |
| `source_reference` | `VARCHAR(100)` | ✔ | | Campaign ID or referral staff name. | `GOOGLE_SEARCH_CAMP_26` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `UNIQUE KEY uq_adm_enq_no (enquiry_no)`
- `KEY idx_adm_enq_cycle (admission_cycle_id)`
- `KEY idx_adm_enq_status (status)`
- `KEY idx_adm_enq_counselor (counselor_id)`
- `KEY idx_adm_enq_mobile (contact_mobile)`
- `KEY idx_adm_enq_sibling (sibling_student_id)`
- `KEY idx_adm_enq_class_sought (class_sought_id)`
- `FOREIGN KEY (admission_cycle_id) REFERENCES adm_admission_cycles (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (class_sought_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (counselor_id) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`
- `FOREIGN KEY (sibling_student_id) REFERENCES std_students (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

### 7. `adm_merit_lists`

#### Purpose & Business Context
Header record governing merit ranking generation per cycle, class, and quota. Stores scoring weightages (test, interview, academic) and cutoff thresholds.

#### Example Row
```json
{
  "id": 8,
  "admission_cycle_id": 1,
  "class_id": 5,
  "quota_type": "General",
  "generated_at": "2026-03-01 16:00:00",
  "generated_by": 12,
  "status": "Published",
  "academic_percentge": 30.00,
  "test_percentge": 50.00,
  "interview_percentge": 20.00,
  "total_score": 100.00,
  "additional_criteria_json": "{\"test_pct\":50,\"interview_pct\":20,\"academic_pct\":30}",
  "sibling_bonus_score": 5,
  "cutoff_score": 50.00,
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `MEDIUMINT UNSIGNED` | — | **PK** | Primary key. | `8` |
| `admission_cycle_id` | `SMALLINT UNSIGNED` | — | **FK** | Associated cycle. | `1` |
| `class_id` | `INT UNSIGNED` | — | **FK** | Associated class. | `5` |
| `quota_type` | `ENUM` | — | | Target quota. | `General` |
| `generated_at` | `TIMESTAMP` | ✔ | | Timestamp when algorithm compiled ranking. | `2026-03-01 16:00:00` |
| `generated_by` | `INT UNSIGNED` | ✔ | **FK** | Staff ID who ran generation (`sys_users.id`). | `12` |
| `status` | `ENUM` | — | **KEY** | Lifecycle: `Draft`, `Published`, `Finalized`. | `Published` |
| `academic_percentge` | `DECIMAL(5,2)` | — | | Prior academic marks weightage %. | `30.00` |
| `test_percentge` | `DECIMAL(5,2)` | — | | Entrance test score weightage %. | `50.00` |
| `interview_percentge` | `DECIMAL(5,2)` | — | | Interview score weightage %. | `20.00` |
| `total_score` | `DECIMAL(5,2)` | — | | Sum of weightages (must equal 100.00). | `100.00` |
| `additional_criteria_json` | `JSON` | ✔ | | Explicit weightage breakdown JSON. | `{"test_pct":50,...}` |
| `sibling_bonus_score` | `TINYINT UNSIGNED` | — | | Sibling score bonus copied from cycle. | `5` |
| `cutoff_score` | `DECIMAL(6,2)` | ✔ | | Minimum score; below cutoff $\rightarrow$ Rejected. | `50.00` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_ml_cycle_class_quota (admission_cycle_id, class_id, quota_type)`
- `KEY idx_adm_ml_status (status)`
- `KEY idx_adm_ml_generated_by (generated_by)`
- `FOREIGN KEY (admission_cycle_id) REFERENCES adm_admission_cycles (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (class_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (generated_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

## LAYER 4: Follow-ups & Formal Applications

### 8. `adm_follow_ups`

#### Purpose & Business Context
Tracks CRM outreach interactions (Calls, Meetings, SMS, Emails, Walk-ins) conducted by counselors against an enquiry, with automated task reminders.

#### Example Row
```json
{
  "id": 240,
  "enquiry_id": 105,
  "follow_up_type": "Call",
  "scheduled_at": "2026-01-20 11:30:00",
  "completed_at": "2026-01-20 11:42:15",
  "outcome": "Interested",
  "notes": "Discussed fee structure. Parent will submit online application.",
  "done_by": 14,
  "reminder_sent": 1,
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `MEDIUMINT UNSIGNED` | — | **PK** | Primary key. | `240` |
| `enquiry_id` | `MEDIUMINT UNSIGNED` | — | **FK** | Linked enquiry. | `105` |
| `follow_up_type` | `ENUM` | — | | `Call`, `Meeting`, `Email`, `SMS`, `Walk-in`. | `Call` |
| `scheduled_at` | `DATETIME` | — | **KEY** | Scheduled interaction timestamp. | `2026-01-20 11:30:00` |
| `completed_at` | `DATETIME` | ✔ | | Actual completion timestamp (`NULL` = pending). | `2026-01-20 11:42:15` |
| `outcome` | `ENUM` | — | **KEY** | `Pending`, `Interested`, `Not_Interested`, `Callback`, `Converted`. | `Interested` |
| `notes` | `TEXT` | ✔ | | Detailed interaction notes. | `Discussed fee...` |
| `done_by` | `INT UNSIGNED` | ✔ | **FK** | Counselor who executed follow-up (`sys_users.id`). | `14` |
| `reminder_sent` | `TINYINT(1)` | — | | `1` = automated reminder dispatched. | `1` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_fu_enquiry (enquiry_id)`
- `KEY idx_adm_fu_scheduled (scheduled_at)`
- `KEY idx_adm_fu_done_by (done_by)`
- `KEY idx_adm_fu_outcome (outcome)`
- `FOREIGN KEY (enquiry_id) REFERENCES adm_enquiries (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (done_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

### 9. `adm_applications`

#### Purpose & Business Context
The central repository for student admission applications. Stores detailed multi-step biographical, demographic, prior academic, guardian, address, and fee confirmation data, governed by a 10-state FSM.

#### Example Row
```json
{
  "id": 88,
  "admission_cycle_id": 1,
  "enquiry_id": 105,
  "application_no": "APP-2026-00088",
  "class_applied_id": 1,
  "quota_type": "General",
  "is_sibling": 1,
  "sibling_student_id": 42,
  "is_staff_ward": 0,
  "student_first_name": "Aarav",
  "student_middle_name": null,
  "student_last_name": "Sharma",
  "student_dob": "2020-05-14",
  "student_gender": "Male",
  "student_religion_id": 1,
  "student_caste_category_id": 1,
  "student_nationality_id": 101,
  "student_mother_tongue_id": 12,
  "aadhar_no": "987654321012",
  "apaar_id": "ABC-2026-998877",
  "birth_cert_no": "BC/2020/9871",
  "blood_group": "B+",
  "known_allergies": "Peanuts",
  "prev_school_name": "Sunshine Montessori",
  "prev_class_passed": "UKG",
  "prev_marks_percent": 88.50,
  "prev_tc_no": "TC-2025-098",
  "father_name": "Vikram Sharma",
  "father_user_id": 35,
  "father_mobile": "9876543210",
  "father_email": "vikram.sharma@example.com",
  "father_occupation": "Software Architect",
  "mother_name": "Neha Sharma",
  "mother_user_id": 36,
  "mother_mobile": "9876543211",
  "mother_email": "neha.sharma@example.com",
  "address_line1": "Flat 402, Royal Palms",
  "city": 14,
  "state": 2,
  "pincode": "400076",
  "application_fee_paid": 1,
  "application_fee_amount": 1500.00,
  "application_fee_date": "2026-01-22",
  "fee_transactions_id": 5512,
  "fee_receipts_id": 3041,
  "interview_scheduled_at": "2026-02-10 10:00:00",
  "interview_score": 85.00,
  "status": "Verified",
  "processed_by": 14,
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `MEDIUMINT UNSIGNED` | — | **PK** | Primary key. | `88` |
| `admission_cycle_id` | `SMALLINT UNSIGNED` | — | **FK** | Associated cycle. | `1` |
| `enquiry_id` | `MEDIUMINT UNSIGNED` | ✔ | **FK** | Converted enquiry reference (`NULL` for direct). | `105` |
| `application_no` | `VARCHAR(20)` | — | **UK** | Auto-generated unique number (`APP-YYYY-NNNNN`). | `APP-2026-00088` |
| `class_applied_id` | `INT UNSIGNED` | — | **FK** | Class applied for (`sch_classes.id`). | `1` |
| `quota_type` | `ENUM` | — | | Quota category chosen by parent. | `General` |
| `is_sibling` | `TINYINT(1)` | — | | `1` = verified sibling (grants sibling bonus). | `1` |
| `sibling_student_id` | `INT UNSIGNED` | ✔ | **FK** | Enrolled sibling reference (`std_students.id`). | `42` |
| `is_staff_ward` | `TINYINT(1)` | — | | `1` = child of current school employee. | `0` |
| `student_first_name` | `VARCHAR(50)` | — | | Applicant first name. | `Aarav` |
| `student_middle_name` | `VARCHAR(50)` | ✔ | | Applicant middle name. | `NULL` |
| `student_last_name` | `VARCHAR(50)` | ✔ | | Applicant last name. | `Sharma` |
| `student_dob` | `DATE` | — | | Date of birth. | `2020-05-14` |
| `student_gender` | `ENUM` | — | | `Male`, `Female`, `Transgender`, `Prefer Not to Say`. | `Male` |
| `student_religion_id` | `INT UNSIGNED` | ✔ | **FK** | FK to `sys_dropdown_table.id`. | `1` |
| `student_caste_category_id` | `INT UNSIGNED` | ✔ | **FK** | FK to `sys_dropdown_table.id`. | `1` |
| `student_nationality_id` | `INT UNSIGNED` | ✔ | **FK** | FK to `sys_dropdown_table.id`. | `101` |
| `student_mother_tongue_id` | `INT UNSIGNED` | ✔ | **FK** | FK to `sys_dropdown_table.id`. | `12` |
| `aadhar_no` | `VARCHAR(20)` | ✔ | | Masked/encrypted Aadhaar number (no DB UK). | `987654321012` |
| `apaar_id` | `VARCHAR(100)` | ✔ | | National Academic Bank of Credits ID. | `ABC-2026-998877` |
| `birth_cert_no` | `VARCHAR(50)` | ✔ | | Birth certificate registration number. | `BC/2020/9871` |
| `blood_group` | `ENUM` | ✔ | | `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`, `Unknown`. | `B+` |
| `known_allergies` | `TEXT` | ✔ | | Medical / allergy details. | `Peanuts` |
| `prev_school_name` | `VARCHAR(100)` | ✔ | | Prior school name. | `Sunshine Montessori` |
| `prev_class_passed` | `VARCHAR(20)` | ✔ | | Prior class passed. | `UKG` |
| `prev_marks_percent` | `DECIMAL(5,2)` | ✔ | | Prior academic marks %. | `88.50` |
| `prev_tc_no` | `VARCHAR(50)` | ✔ | | Prior transfer certificate number. | `TC-2025-098` |
| `father_name` | `VARCHAR(100)` | ✔ | | Father full name. | `Vikram Sharma` |
| `father_user_id` | `INT UNSIGNED` | ✔ | **FK** | Linked user account if sibling exists. | `35` |
| `father_mobile` | `VARCHAR(15)` | ✔ | | Father contact phone. | `9876543210` |
| `father_email` | `VARCHAR(100)` | ✔ | | Father email. | `vikram.sharma@example.com` |
| `mother_name` | `VARCHAR(100)` | ✔ | | Mother full name. | `Neha Sharma` |
| `mother_user_id` | `INT UNSIGNED` | ✔ | **FK** | Linked user account if sibling exists. | `36` |
| `mother_mobile` | `VARCHAR(15)` | ✔ | | Mother contact phone. | `9876543211` |
| `mother_email` | `VARCHAR(100)` | ✔ | | Mother email. | `neha.sharma@example.com` |
| `address_line1` | `VARCHAR(150)` | ✔ | | Primary street address. | `Flat 402, Royal Palms` |
| `city` | `INT UNSIGNED` | ✔ | **FK** | FK to `glb_cities.id`. | `14` |
| `state` | `INT UNSIGNED` | ✔ | **FK** | FK to `glb_states.id`. | `2` |
| `pincode` | `VARCHAR(10)` | ✔ | | Postal code. | `400076` |
| `application_fee_paid` | `TINYINT(1)` | — | | `1` = fee confirmed via gateway or waiver. | `1` |
| `application_fee_amount` | `DECIMAL(12,2)`| ✔ | | Amount paid in INR. | `1500.00` |
| `fee_transactions_id` | `INT UNSIGNED` | ✔ | **FK** | FK to `fee_transactions.id`. | `5512` |
| `fee_receipts_id` | `INT UNSIGNED` | ✔ | **FK** | FK to `fee_receipts.id`. | `3041` |
| `interview_scheduled_at` | `DATETIME` | ✔ | | Scheduled interview date-time. | `2026-02-10 10:00:00` |
| `interview_score` | `DECIMAL(5,2)` | ✔ | | Evaluated interview mark. | `85.00` |
| `status` | `ENUM` | — | **KEY** | 10-state FSM: `Draft`, `Submitted`, `Under_Review`, `Verified`, `Shortlisted`, `Rejected`, `Waitlisted`, `Allotted`, `Enrolled`, `Withdrawn`. | `Verified` |
| `rejection_reason` | `TEXT` | ✔ | | Required when status = `Rejected`. | `NULL` |
| `processed_by` | `INT UNSIGNED` | ✔ | **FK** | Staff ID handling application (`sys_users.id`). | `14` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `UNIQUE KEY uq_adm_app_no (application_no)`
- `KEY idx_adm_app_cycle (admission_cycle_id)`
- `KEY idx_adm_app_status (status)`
- `KEY idx_adm_app_class (class_applied_id)`
- `KEY idx_adm_app_enquiry (enquiry_id)`
- `KEY idx_adm_app_sibling (sibling_student_id)`
- `KEY idx_adm_app_processed_by (processed_by)`
- `FOREIGN KEY (admission_cycle_id) REFERENCES adm_admission_cycles (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (enquiry_id) REFERENCES adm_enquiries (id) ON DELETE SET NULL ON UPDATE CASCADE`
- `FOREIGN KEY (class_applied_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (sibling_student_id) REFERENCES std_students (id) ON DELETE SET NULL ON UPDATE CASCADE`
- `FOREIGN KEY (processed_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

## LAYER 5: Verification, Logs, Candidates & Rankings

### 10. `adm_application_documents`

#### Purpose & Business Context
Stores uploaded KYC document files for an application against checklist requirements. Tracks digital verification status, rejection remarks, and physical custody of original documents.

#### Example Row
```json
{
  "id": 312,
  "application_id": 88,
  "checklist_item_id": 10,
  "media_id": 204,
  "original_filename": "Aarav_Birth_Certificate.pdf",
  "verification_status": "Verified",
  "verification_remarks": null,
  "verified_by": 18,
  "verified_at": "2026-01-25 14:10:00",
  "is_physically_received": 1,
  "physically_received_at": "2026-01-28",
  "physically_received_by": 22,
  "is_active": 1
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `312` |
| `application_id` | `BIGINT UNSIGNED` | — | **FK, UK** | Associated application. | `88` |
| `checklist_item_id` | `BIGINT UNSIGNED` | — | **FK, UK** | Associated checklist definition. | `10` |
| `media_id` | `INT UNSIGNED` | — | **FK** | Binary storage reference (`sys_media.id`). | `204` |
| `original_filename` | `VARCHAR(255)` | — | | Name of file as uploaded by parent. | `Aarav_Birth_Certificate.pdf` |
| `verification_status`| `ENUM` | — | **KEY** | `Pending`, `Verified`, `Rejected`. | `Verified` |
| `verification_remarks`| `TEXT` | ✔ | | Mandatory remark if status = `Rejected`. | `NULL` |
| `verified_by` | `INT UNSIGNED` | ✔ | **FK** | Verifying officer (`sys_users.id`). | `18` |
| `verified_at` | `TIMESTAMP` | ✔ | | Digital verification timestamp. | `2026-01-25 14:10:00` |
| `is_physically_received`| `TINYINT(1)`| — | | `1` = original physical document in school custody. | `1` |
| `physically_received_at`| `DATE` | ✔ | | Date physical copy collected. | `2026-01-28` |
| `physically_received_by`| `BIGINT UNSIGNED`| ✔ | **FK** | Front desk staff collecting original. | `22` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `UNIQUE KEY uq_adm_doc_app_checklist (application_id, checklist_item_id)`
- `KEY idx_adm_doc_app (application_id)`
- `KEY idx_adm_doc_checklist (checklist_item_id)`
- `KEY idx_adm_doc_media (media_id)`
- `KEY idx_adm_doc_verified_by (verified_by)`
- `KEY idx_adm_doc_vstatus (verification_status)`
- `FOREIGN KEY (application_id) REFERENCES adm_applications (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (checklist_item_id) REFERENCES adm_document_checklist (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (media_id) REFERENCES sys_media (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (verified_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

### 11. `adm_application_stages_log`

#### Purpose & Business Context
Provides an unalterable, append-only audit trail recording every state change experienced by an application, capturing the initiating user, timestamp, and transition rationale.

#### Example Row
```json
{
  "id": 940,
  "application_id": 88,
  "from_status": "Submitted",
  "to_status": "Under_Review",
  "remarks": "Counselor claimed application for verification.",
  "changed_by": 14,
  "changed_at": "2026-01-23 09:30:00"
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `940` |
| `application_id` | `BIGINT UNSIGNED` | — | **FK** | Linked application. | `88` |
| `from_status` | `VARCHAR(50)` | — | | Originating status string. | `Submitted` |
| `to_status` | `VARCHAR(50)` | — | | Target status string. | `Under_Review` |
| `remarks` | `TEXT` | ✔ | | Contextual rationale for change. | `Counselor claimed...` |
| `changed_by` | `INT UNSIGNED` | ✔ | **FK** | User executing transition (`NULL` = system). | `14` |
| `changed_at` | `TIMESTAMP` | — | **KEY** | Exact timestamp of change. | `2026-01-23 09:30:00` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_stage_app (application_id)`
- `KEY idx_adm_stage_changed_at (changed_at)`
- `KEY idx_adm_stage_changed_by (changed_by)`
- `FOREIGN KEY (application_id) REFERENCES adm_applications (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (changed_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

### 12. `adm_entrance_test_candidates`

#### Purpose & Business Context
Registers candidates for a scheduled entrance examination, assigns hall roll numbers, and captures evaluated marks with subject-wise score breakdowns.

#### Example Row
```json
{
  "id": 65,
  "entrance_test_id": 3,
  "application_id": 88,
  "roll_no": "ROLL-05-042",
  "marks_obtained": 84.50,
  "result": "Pass",
  "subject_marks_json": "[{\"subject\":\"Maths\",\"marks\":42.5},{\"subject\":\"English\",\"max\":42.0}]"
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `65` |
| `entrance_test_id` | `BIGINT UNSIGNED` | — | **FK, UK** | Test session (`adm_entrance_tests.id`). | `3` |
| `application_id` | `BIGINT UNSIGNED` | — | **FK, UK** | Candidate application. | `88` |
| `roll_no` | `VARCHAR(20)` | ✔ | | Exam hall roll number. | `ROLL-05-042` |
| `marks_obtained` | `DECIMAL(6,2)` | ✔ | | Evaluated total marks (`NULL` = pending). | `84.50` |
| `result` | `ENUM` | — | **KEY** | `Pass`, `Fail`, `Absent`, `Pending`. | `Pass` |
| `subject_marks_json` | `JSON` | ✔ | | Per-subject score breakdown. | `[{"subject":"Maths","marks":42.5}]` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `UNIQUE KEY uq_adm_etc_test_app (entrance_test_id, application_id)`
- `KEY idx_adm_etc_test (entrance_test_id)`
- `KEY idx_adm_etc_app (application_id)`
- `KEY idx_adm_etc_result (result)`
- `FOREIGN KEY (entrance_test_id) REFERENCES adm_entrance_tests (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (application_id) REFERENCES adm_applications (id) ON DELETE CASCADE ON UPDATE CASCADE`

---

### 13. `adm_merit_list_entries`

#### Purpose & Business Context
Maintains individual applicant ranking rows within a published merit list. Records composite scores, component breakdowns, sibling bonuses, and merit statuses (`Shortlisted`, `Waitlisted`, `Rejected`).

#### Example Row
```json
{
  "id": 140,
  "merit_list_id": 8,
  "application_id": 88,
  "merit_rank": 3,
  "composite_score": 89.25,
  "entrance_score": 42.25,
  "interview_score": 17.00,
  "academic_score": 25.00,
  "sibling_bonus_applied": 1,
  "merit_status": "Shortlisted",
  "is_active": 1,
  "created_by": 12,
  "updated_by": 12
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `140` |
| `merit_list_id` | `BIGINT UNSIGNED` | — | **FK** | Header list (`adm_merit_lists.id`). | `8` |
| `application_id` | `BIGINT UNSIGNED` | — | **FK** | Candidate application. | `88` |
| `merit_rank` | `SMALLINT UNSIGNED` | — | **KEY** | Sequential position in merit ranking (1 = top). | `3` |
| `composite_score` | `DECIMAL(6,2)` | ✔ | **KEY** | Final normalized score (0–100). | `89.25` |
| `entrance_score` | `DECIMAL(6,2)` | ✔ | | Weighted entrance test component score. | `42.25` |
| `interview_score` | `DECIMAL(6,2)` | ✔ | | Weighted interview component score. | `17.00` |
| `academic_score` | `DECIMAL(6,2)` | ✔ | | Weighted prior academic marks component. | `25.00` |
| `sibling_bonus_applied`| `TINYINT(1)` | — | | `1` = sibling points added to composite score. | `1` |
| `merit_status` | `ENUM` | — | **KEY** | `Shortlisted`, `Waitlisted`, `Rejected`. | `Shortlisted` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_mle_list (merit_list_id)`
- `KEY idx_adm_mle_rank (merit_list_id, merit_rank)`
- `KEY idx_adm_mle_app (application_id)`
- `KEY idx_adm_mle_status (merit_status)`
- `KEY idx_adm_mle_score (composite_score)`
- `FOREIGN KEY (merit_list_id) REFERENCES adm_merit_lists (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (application_id) REFERENCES adm_applications (id) ON DELETE RESTRICT ON UPDATE CASCADE`

---

## LAYER 6: Allotments & Promotion Batches

### 14. `adm_allotments`

#### Purpose & Business Context
Represents provisional seat allocations offered to shortlisted applicants. Manages offer deadlines, offer letter PDF storage, fee settlements, and links directly to `std_students.id` upon enrollment.

#### Example Row
```json
{
  "id": 52,
  "merit_list_entry_id": 140,
  "application_id": 88,
  "admission_no": "DPS/2026/0142",
  "allotted_class_id": 1,
  "allotted_section_id": 3,
  "joining_date": "2026-04-05",
  "offer_letter_media_id": 418,
  "offer_issued_at": "2026-03-02 10:00:00",
  "offer_expires_at": "2026-03-12",
  "admission_fee_paid": 1,
  "admission_fee_amount": 25000.00,
  "admission_fee_date": "2026-03-05",
  "status": "Enrolled",
  "enrolled_student_id": 1054,
  "is_active": 1,
  "created_by": 12,
  "updated_by": 12
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `52` |
| `merit_list_entry_id` | `BIGINT UNSIGNED` | — | **FK** | Ranking reference. | `140` |
| `application_id` | `BIGINT UNSIGNED` | — | **FK** | Candidate application. | `88` |
| `admission_no` | `VARCHAR(50)` | ✔ | **UK** | Formal admission number (`NULL` until offer). | `DPS/2026/0142` |
| `allotted_class_id` | `INT UNSIGNED` | — | **FK** | Allotted class (`sch_classes.id`). | `1` |
| `allotted_section_id` | `INT UNSIGNED` | ✔ | **FK** | Section assigned (`NULL` before enrollment). | `3` |
| `joining_date` | `DATE` | ✔ | | Date student is expected to attend classes. | `2026-04-05` |
| `offer_letter_media_id`| `INT UNSIGNED` | ✔ | **FK** | Offer letter PDF reference (`sys_media.id`). | `418` |
| `offer_issued_at` | `TIMESTAMP` | ✔ | | Offer letter issuance timestamp. | `2026-03-02 10:00:00` |
| `offer_expires_at` | `DATE` | ✔ | **KEY** | Expiration deadline for fee payment. | `2026-03-12` |
| `admission_fee_paid` | `TINYINT(1)` | — | | `1` = seat acceptance fee settled. | `1` |
| `admission_fee_amount` | `DECIMAL(10,2)`| ✔ | | Admission fee amount paid. | `25000.00` |
| `admission_fee_date` | `DATE` | ✔ | | Date fee was received. | `2026-03-05` |
| `status` | `ENUM` | — | **KEY** | `Offered`, `Accepted`, `Declined`, `Expired`, `Enrolled`, `Withdrawn`. | `Enrolled` |
| `enrolled_student_id` | `INT UNSIGNED` | ✔ | **FK** | Enrolled student master link (`std_students.id`). | `1054` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `UNIQUE KEY uq_adm_allot_admission_no (admission_no)`
- `KEY idx_adm_allot_mle (merit_list_entry_id)`
- `KEY idx_adm_allot_app (application_id)`
- `KEY idx_adm_allot_status (status)`
- `KEY idx_adm_allot_expires (offer_expires_at)`
- `KEY idx_adm_allot_enrolled_student (enrolled_student_id)`
- `KEY idx_adm_allot_class (allotted_class_id)`
- `KEY idx_adm_allot_section (allotted_section_id)`
- `FOREIGN KEY (merit_list_entry_id) REFERENCES adm_merit_list_entries (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (application_id) REFERENCES adm_applications (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (allotted_class_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (allotted_section_id) REFERENCES sch_sections (id) ON DELETE SET NULL ON UPDATE CASCADE`
- `FOREIGN KEY (offer_letter_media_id) REFERENCES sys_media (id) ON DELETE SET NULL ON UPDATE CASCADE`
- `FOREIGN KEY (enrolled_student_id) REFERENCES std_students (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

### 15. `adm_promotion_batches`

#### Purpose & Business Context
Defines a year-end academic cohort promotion run, specifying source/target academic sessions and classes, pass criteria, and aggregate execution counts.

#### Example Row
```json
{
  "id": 14,
  "from_session_id": 3,
  "to_session_id": 4,
  "from_class_id": 4,
  "to_class_id": 5,
  "criteria_json": "{\"min_pass_pct\":33,\"use_exam_results\":true}",
  "total_students": 120,
  "promoted_count": 115,
  "detained_count": 5,
  "status": "Confirmed",
  "processed_by": 8,
  "processed_at": "2026-03-25 15:30:00",
  "is_active": 1,
  "created_by": 8,
  "updated_by": 8
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `14` |
| `from_session_id` | `INT UNSIGNED` | — | **FK** | Current academic session ID. | `3` |
| `to_session_id` | `INT UNSIGNED` | — | **FK** | Target next academic session ID. | `4` |
| `from_class_id` | `INT UNSIGNED` | — | **FK** | Source class ID. | `4` |
| `to_class_id` | `INT UNSIGNED` | — | **FK** | Target promoted class ID. | `5` |
| `criteria_json` | `JSON` | ✔ | | Academic rules for automatic promotion. | `{"min_pass_pct":33}` |
| `total_students` | `INT UNSIGNED` | — | | Total students loaded into batch. | `120` |
| `promoted_count` | `INT UNSIGNED` | — | | Count promoted upon confirmation. | `115` |
| `detained_count` | `INT UNSIGNED` | — | | Count detained upon confirmation. | `5` |
| `status` | `ENUM` | — | **KEY** | Lifecycle: `Draft`, `Confirmed`. | `Confirmed` |
| `processed_by` | `INT UNSIGNED` | ✔ | **FK** | Authorizing user (`sys_users.id`). | `8` |
| `processed_at` | `TIMESTAMP` | ✔ | | Timestamp when committed. | `2026-03-25 15:30:00` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_pb_from_session (from_session_id)`
- `KEY idx_adm_pb_status (from_session_id, from_class_id, status)`
- `KEY idx_adm_pb_to_session (to_session_id)`
- `KEY idx_adm_pb_from_class (from_class_id)`
- `KEY idx_adm_pb_to_class (to_class_id)`
- `KEY idx_adm_pb_processed_by (processed_by)`
- `FOREIGN KEY (from_session_id) REFERENCES sch_org_academic_sessions_jnt (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (to_session_id) REFERENCES sch_org_academic_sessions_jnt (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (from_class_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (to_class_id) REFERENCES sch_classes (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (processed_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

## LAYER 7: Withdrawals & Promotion Records

### 16. `adm_withdrawals`

#### Purpose & Business Context
Records admission cancellations and student withdrawals, computing fee refund eligibility dynamically via the cycle's refund policy tiers and tracking finance disbursement.

#### Example Row
```json
{
  "id": 19,
  "application_id": 88,
  "allotment_id": 52,
  "withdrawal_date": "2026-03-10",
  "reason": "Relocation",
  "remarks": "Parent transferred to Bangalore office.",
  "fee_paid_amount": 26500.00,
  "refund_eligible_amount": 21200.00,
  "refund_status": "Approved",
  "refund_processed_at": null,
  "processed_by": 6,
  "is_active": 1,
  "created_by": 14,
  "updated_by": 6
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `19` |
| `application_id` | `BIGINT UNSIGNED` | — | **FK** | Associated application. | `88` |
| `allotment_id` | `BIGINT UNSIGNED` | ✔ | **FK** | Associated allotment (`NULL` if pre-offer). | `52` |
| `withdrawal_date` | `DATE` | — | | Official date of withdrawal request. | `2026-03-10` |
| `reason` | `ENUM` | — | | `Personal`, `Financial`, `Relocation`, `School_Change`, `Medical`, `Other`. | `Relocation` |
| `remarks` | `TEXT` | ✔ | | Contextual remarks. | `Parent transferred...` |
| `fee_paid_amount` | `DECIMAL(10,2)`| — | | Total fees paid before withdrawal. | `26500.00` |
| `refund_eligible_amount`| `DECIMAL(10,2)`| — | | Calculated refund per `refund_policy_json`. | `21200.00` |
| `refund_status` | `ENUM` | — | **KEY** | `Not_Eligible`, `Pending`, `Approved`, `Paid`. | `Approved` |
| `refund_processed_at` | `DATE` | ✔ | | Date refund was disbursed by Finance. | `NULL` |
| `processed_by` | `INT UNSIGNED` | ✔ | **FK** | Finance officer processing refund. | `6` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_wd_app (application_id)`
- `KEY idx_adm_wd_allotment (allotment_id)`
- `KEY idx_adm_wd_refund_status (refund_status)`
- `KEY idx_adm_wd_processed_by (processed_by)`
- `FOREIGN KEY (application_id) REFERENCES adm_applications (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (allotment_id) REFERENCES adm_allotments (id) ON DELETE SET NULL ON UPDATE CASCADE`
- `FOREIGN KEY (processed_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

### 17. `adm_promotion_records`

#### Purpose & Business Context
Contains the individual student decisions (Promoted, Detained, Transferred, Alumni, Left) and new section/roll number assignments within a promotion batch.

#### Example Row
```json
{
  "id": 482,
  "promotion_batch_id": 14,
  "student_id": 1054,
  "from_class_section_id": 21,
  "to_class_section_id": 29,
  "new_roll_no": 14,
  "result": "Promoted",
  "remarks": "Promoted with distinction in mathematics.",
  "is_active": 1,
  "created_by": 8,
  "updated_by": 8
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `482` |
| `promotion_batch_id` | `BIGINT UNSIGNED` | — | **FK** | Linked batch header. | `14` |
| `student_id` | `INT UNSIGNED` | — | **FK** | Target student (`std_students.id`). | `1054` |
| `from_class_section_id`| `INT UNSIGNED` | — | **FK** | Current class-section junction ID. | `21` |
| `to_class_section_id` | `INT UNSIGNED` | ✔ | **FK** | Target class-section junction ID. | `29` |
| `new_roll_no` | `SMALLINT UNSIGNED` | ✔ | | Assigned roll number in new section. | `14` |
| `result` | `ENUM` | — | | `Promoted`, `Detained`, `Transferred`, `Alumni`, `Left`. | `Promoted` |
| `remarks` | `TEXT` | ✔ | | Teacher or exam evaluation remarks. | `Promoted with distinction...` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_pr_batch (promotion_batch_id)`
- `KEY idx_adm_pr_student (promotion_batch_id, student_id)`
- `KEY idx_adm_pr_student_id (student_id)`
- `KEY idx_adm_pr_from_section (from_class_section_id)`
- `KEY idx_adm_pr_to_section (to_class_section_id)`
- `FOREIGN KEY (promotion_batch_id) REFERENCES adm_promotion_batches (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (student_id) REFERENCES std_students (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (from_class_section_id) REFERENCES sch_class_section_jnt (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (to_class_section_id) REFERENCES sch_class_section_jnt (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

## LAYER 8: Leaver Documents & Disciplinary Incidents

### 18. `adm_transfer_certificates`

#### Purpose & Business Context
Stores statutory Transfer Certificates (TC) issued to departing students. Enforces mandatory fee clearance (`BR-ADM-004`), generates verifiable QR code PDFs, and supports duplicate re-issuance.

#### Example Row
```json
{
  "id": 77,
  "student_id": 890,
  "tc_number": "TC-2026-00077",
  "issue_date": "2026-03-28",
  "leaving_date": "2026-03-31",
  "class_at_leaving": "Class 10-A",
  "reason_for_leaving": "Completed secondary education.",
  "conduct": "Excellent",
  "destination_school": "National Junior College",
  "academic_status": "Class 10 Passed (CBSE)",
  "fees_cleared": 1,
  "is_duplicate": 0,
  "original_tc_id": null,
  "media_id": 512,
  "issued_by": 8,
  "is_active": 1,
  "created_by": 8,
  "updated_by": 8
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `77` |
| `student_id` | `INT UNSIGNED` | — | **FK** | Departing student (`std_students.id`). | `890` |
| `tc_number` | `VARCHAR(30)` | — | **UK** | Formal sequential number (`TC-YYYY-NNNNN`). | `TC-2026-00077` |
| `issue_date` | `DATE` | — | **KEY** | Date of official issuance. | `2026-03-28` |
| `leaving_date` | `DATE` | — | | Last recorded date of student attendance. | `2026-03-31` |
| `class_at_leaving` | `VARCHAR(30)` | — | | Class and section description at departure. | `Class 10-A` |
| `reason_for_leaving` | `TEXT` | ✔ | | Reason recorded on certificate. | `Completed secondary...` |
| `conduct` | `ENUM` | — | | Conduct grade: `Excellent`, `Good`, `Satisfactory`, `Poor`. | `Excellent` |
| `destination_school` | `VARCHAR(150)`| ✔ | | Next institution (if known). | `National Junior College` |
| `academic_status` | `VARCHAR(100)`| ✔ | | Final academic standing. | `Class 10 Passed` |
| `fees_cleared` | `TINYINT(1)` | — | | Mandatory check: `1` = no outstanding fee dues. | `1` |
| `is_duplicate` | `TINYINT(1)` | — | | `1` = re-issued duplicate copy. | `0` |
| `original_tc_id` | `BIGINT UNSIGNED` | ✔ | **FK** | Self-reference to first issued TC if duplicate. | `NULL` |
| `media_id` | `INT UNSIGNED` | ✔ | **FK** | Stored PDF file with QR code (`sys_media.id`). | `512` |
| `issued_by` | `INT UNSIGNED` | ✔ | **FK** | Principal or admin issuing TC (`sys_users.id`).| `8` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `UNIQUE KEY uq_adm_tc_number (tc_number)`
- `KEY idx_adm_tc_student (student_id)`
- `KEY idx_adm_tc_issue_date (issue_date)`
- `KEY idx_adm_tc_original (original_tc_id)`
- `KEY idx_adm_tc_media (media_id)`
- `KEY idx_adm_tc_issued_by (issued_by)`
- `FOREIGN KEY (student_id) REFERENCES std_students (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (original_tc_id) REFERENCES adm_transfer_certificates (id) ON DELETE SET NULL ON UPDATE CASCADE`
- `FOREIGN KEY (media_id) REFERENCES sys_media (id) ON DELETE SET NULL ON UPDATE CASCADE`
- `FOREIGN KEY (issued_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

### 19. `adm_behavior_incidents`

#### Purpose & Business Context
Logs disciplinary and behavioral infractions involving students. Tracks severity, location, witnesses, signed conduct score deductions, and triggers automated alerts for critical events.

#### Example Row
```json
{
  "id": 110,
  "student_id": 1054,
  "incident_date": "2026-02-14",
  "incident_type": "Disruption",
  "severity": "Medium",
  "description": "Repeated classroom disruption during science laboratory practical.",
  "location": "Science Lab 2",
  "witnesses_json": "[\"Sunil Rao (Lab Assistant)\",\"Pooja Sen (Teacher)\"]",
  "reported_by": 24,
  "parent_notified": 1,
  "parent_notified_at": "2026-02-14 16:30:00",
  "status": "Action_Taken",
  "behavior_score_impact": -5,
  "is_active": 1,
  "created_by": 24,
  "updated_by": 8
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `110` |
| `student_id` | `INT UNSIGNED` | — | **FK** | Infringing student (`std_students.id`). | `1054` |
| `incident_date` | `DATE` | — | **KEY** | Date infraction occurred. | `2026-02-14` |
| `incident_type` | `ENUM` | — | | `Bullying`, `Cheating`, `Disruption`, `Absenteeism`, `Vandalism`, `Violence`, `Misconduct`, `Other`. | `Disruption` |
| `severity` | `ENUM` | — | **KEY** | `Low`, `Medium`, `High`, `Critical`. | `Medium` |
| `description` | `TEXT` | — | | Detailed factual narrative. | `Repeated classroom...` |
| `location` | `VARCHAR(100)` | ✔ | | Campus location. | `Science Lab 2` |
| `witnesses_json` | `JSON` | ✔ | | Array of staff/student witness names. | `["Sunil Rao",...]` |
| `reported_by` | `INT UNSIGNED` | ✔ | **FK** | Reporting staff member (`sys_users.id`). | `24` |
| `parent_notified` | `TINYINT(1)` | — | | `1` = automated SMS/email alert sent to parent. | `1` |
| `parent_notified_at` | `TIMESTAMP` | ✔ | | Notification dispatch timestamp. | `2026-02-14 16:30:00` |
| `status` | `ENUM` | — | **KEY** | `Open`, `Action_Taken`, `Closed`, `Escalated`.| `Action_Taken` |
| `behavior_score_impact`| `TINYINT` | — | | Signed score deduction (e.g. -5, -15). | `-5` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_bi_student_date (student_id, incident_date)`
- `KEY idx_adm_bi_severity (severity)`
- `KEY idx_adm_bi_status (status)`
- `KEY idx_adm_bi_reported_by (reported_by)`
- `FOREIGN KEY (student_id) REFERENCES std_students (id) ON DELETE RESTRICT ON UPDATE CASCADE`
- `FOREIGN KEY (reported_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`

---

## LAYER 9: Disciplinary Corrective Actions

### 20. `adm_behavior_actions`

#### Purpose & Business Context
Records corrective disciplinary actions assigned to address an incident (e.g., Warnings, Detention, Suspension, Counseling), tracking schedules and parent meeting outcomes.

#### Example Row
```json
{
  "id": 45,
  "incident_id": 110,
  "action_type": "Parent_Meeting",
  "description": "Counseling session with parents regarding classroom focus.",
  "start_date": "2026-02-16",
  "end_date": "2026-02-16",
  "parent_meeting_date": "2026-02-16 11:00:00",
  "meeting_outcome": "Parents committed to monitoring homework and digital device time.",
  "action_by": 8,
  "is_active": 1,
  "created_by": 8,
  "updated_by": 8
}
```

#### Columns
| Column | Type | Null | Key | Description & Constraints | Example Value |
|---|---|:---:|:---:|---|---|
| `id` | `BIGINT UNSIGNED` | — | **PK** | Primary key. | `45` |
| `incident_id` | `BIGINT UNSIGNED` | — | **FK** | Associated incident (`adm_behavior_incidents.id`).| `110` |
| `action_type` | `ENUM` | — | **KEY** | `Warning`, `Detention`, `Suspension`, `Expulsion`, `Parent_Meeting`, `Counseling`, `Community_Service`. | `Parent_Meeting` |
| `description` | `TEXT` | ✔ | | Action plan details. | `Counseling session...` |
| `start_date` | `DATE` | ✔ | | Effective start date. | `2026-02-16` |
| `end_date` | `DATE` | ✔ | | Effective end date; must be $\ge \text{start\_date}$. | `2026-02-16` |
| `parent_meeting_date` | `DATETIME` | ✔ | | Scheduled parent conference timestamp. | `2026-02-16 11:00:00` |
| `meeting_outcome` | `TEXT` | ✔ | | Documented parent meeting minutes. | `Parents committed to...` |
| `action_by` | `INT UNSIGNED` | ✔ | **FK** | Staff member enforcing action (`sys_users.id`). | `8` |
| `is_active` | `TINYINT(1)` | — | | Soft enable/disable flag. | `1` |

#### Keys & Constraints
- `PRIMARY KEY (id)`
- `KEY idx_adm_ba_incident (incident_id)`
- `KEY idx_adm_ba_action_by (action_by)`
- `KEY idx_adm_ba_action_type (action_type)`
- `FOREIGN KEY (incident_id) REFERENCES adm_behavior_incidents (id) ON DELETE CASCADE ON UPDATE CASCADE`
- `FOREIGN KEY (action_by) REFERENCES sys_users (id) ON DELETE SET NULL ON UPDATE CASCADE`
