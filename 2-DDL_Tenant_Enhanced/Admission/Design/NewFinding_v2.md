# Admission Management Module — Schema Gaps, Structural Findings & Feature Enhancements

**Document ID:** ADM-FINDINGS-V2  
**Version:** 2.0  
**Date:** 2026-09-23  
**Target Module:** Admission Management (`Modules\Admission`)  
**Analyzed Schema:** `Admission_DDL_v2.sql` (20 Tables)  
**Governing Documents:** `Admission_BRD_v2.md`, `Admission_Solution_Design_v2.md`, `Admission_Data_Dictionary_v2.md`, `Admission_Process_Flow_v2.md`  
**File Location:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Admission/Design/NewFinding_v2.md`  

---

## Executive Summary

During the comprehensive architectural review and documentation of `Admission_DDL_v2.sql`, a series of **critical schema-level bugs, relational mismatches, commented-out audit columns, missing operational workflows, and high-value feature enhancement opportunities** were identified.

This document serves as an actionable engineering punch list. It divides all findings into five distinct categories:
1. **Critical DDL Syntax & Foreign Key Bugs** (Will fail execution or corrupt relational integrity).
2. **Missing Database Columns & Schema Inconsistencies** (Gaps in existing tables).
3. **Missing Relational Tables & Structural Enhancements** (Entities needed for real-world school operations).
4. **Statutory & Institutional Compliance Gaps** (NEP 2020, RTE, CBSE/ICSE affiliation, UDISE+).
5. **Advanced Feature Enhancements** (AI automation, omni-channel WhatsApp, transport/hostel integration).

---

## 1. Critical DDL Syntax & Foreign Key Bugs

These are physical bugs present in `Admission_DDL_v2.sql` that will trigger MySQL syntax/runtime errors upon deployment or cause data corruption.

### BUG-01: Foreign Key Column Name Mismatch in `adm_applications`
- **Feature Detail:** Missing / Bug
- **Affected Table:** `adm_applications` (Lines 305–308 vs Lines 374–377)
- **Description:**  
  In `Admission_DDL_v2.sql`, the columns for master dropdown linkages are declared with `_id` suffix:
  ```sql
  `student_religion_id`       INT UNSIGNED DEFAULT NULL,
  `student_caste_category_id` INT UNSIGNED DEFAULT NULL,
  `student_nationality_id`    INT UNSIGNED DEFAULT NULL,
  `student_mother_tongue_id`  INT UNSIGNED DEFAULT NULL,
  ```
  However, the table's `FOREIGN KEY` definitions at the bottom reference legacy column names without `_id`:
  ```sql
  CONSTRAINT `fk_adm_app_student_religion` FOREIGN KEY (`student_religion`) REFERENCES `sys_dropdown_table` (`id`)
  CONSTRAINT `fk_adm_app_student_caste_category` FOREIGN KEY (`student_caste_category`) REFERENCES `sys_dropdown_table` (`id`)
  CONSTRAINT `fk_adm_app_student_nationality` FOREIGN KEY (`student_nationality`) REFERENCES `sys_dropdown_table` (`id`)
  CONSTRAINT `fk_adm_app_student_mother_tongue` FOREIGN KEY (`student_mother_tongue`) REFERENCES `sys_dropdown_table` (`id`)
  ```
- **Consequence:** MySQL will throw error `ER_KEY_COLUMN_DOES_NOT_EXITS` (Error 1072: Key column 'student_religion' doesn't exist in table) and fail DDL migration.
- **Recommended Fix:** Update the foreign key column targets to match the defined column names:
  ```sql
  CONSTRAINT `fk_adm_app_student_religion` FOREIGN KEY (`student_religion_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_student_caste_category` FOREIGN KEY (`student_caste_category_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_student_nationality` FOREIGN KEY (`student_nationality_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_adm_app_student_mother_tongue` FOREIGN KEY (`student_mother_tongue_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ```

---

### BUG-02: Missing Foreign Key Constraint for `offline_test_media_id`
- **Feature Detail:** Missing / Bug
- **Affected Table:** `adm_entrance_tests` (Line 156 vs Lines 171–173)
- **Description:**  
  Column `offline_test_media_id INT UNSIGNED NULL` is declared in `adm_entrance_tests` to link uploaded examination papers to `sys_media.id`. However, no foreign key constraint `fk_adm_et_media_id` is defined at the bottom of the table.
- **Consequence:** Deleting a media file in `sys_media` leaves orphaned media references in `adm_entrance_tests` with no referential integrity check.
- **Recommended Fix:** Add constraint:
  ```sql
  CONSTRAINT `fk_adm_et_media_id` FOREIGN KEY (`offline_test_media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
  ```

---

### BUG-03: Typographical Errors in Mathematical Column Names
- **Feature Detail:** Missing / Typo
- **Affected Table:** `adm_merit_lists` (Lines 235–237)
- **Description:**  
  The weightage column names have typographical spelling errors:
  - `academic_percentge` (Missing 'a')
  - `test_percentge` (Missing 'a')
  - `interview_percentge` (Missing 'a')
- **Consequence:** Causes discrepancies in Eloquent model property names, JSON API payloads, and query filters.
- **Recommended Fix:** Rename to standardized English:
  - `academic_percentage`
  - `test_percentage`
  - `interview_percentage`

---

## 2. Missing Database Columns & Schema Inconsistencies

These are structural omissions within the existing 20 tables that degrade operational performance or limit business tracking.

### GAP-01: Inconsistent Audit Columns Across Schema Layers
- **Feature Detail:** Missing / Inconsistency
- **Affected Tables:** `adm_admission_cycles`, `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity`, `adm_entrance_tests`, `adm_enquiries`, `adm_follow_ups`, `adm_applications` (Lines 39–40, 69–70, 95–96, 121–122, 162–163, 205–206, 272–273, 356–357)
- **Description:**  
  In the first 4 layers (master and application tables), `created_by` and `updated_by` are commented out (`-- created_by BIGINT UNSIGNED NOT NULL`), whereas in later layers (`adm_merit_list_entries`, `adm_allotments`, `adm_promotion_batches`, `adm_withdrawals`, `adm_transfer_certificates`), they are active.
- **Consequence:** Inability to audit who created or last modified admission cycles, checklist templates, seat quotas, entrance tests, enquiries, and submitted applications.
- **Recommended Fix:** Uncomment and enforce `created_by` and `updated_by` across all 20 tables for uniform compliance.

---

### GAP-02: Next Follow-Up Cache & Lead Scoring on `adm_enquiries`
- **Feature Detail:** Missing / Performance Optimization
- **Affected Table:** `adm_enquiries`
- **Description:**  
  Counselors frequently query "Today's Scheduled Follow-ups" or "Overdue Leads". Currently, determining an enquiry's next scheduled touchpoint requires an aggregate subquery on `adm_follow_ups`. Furthermore, there is no field to prioritize hot vs cold leads.
- **Recommended Additions:**
  ```sql
  `next_follow_up_date` DATETIME NULL,               -- Cached from earliest pending adm_follow_ups.scheduled_at
  `last_contacted_at`   DATETIME NULL,               -- Cached from latest completed adm_follow_ups.completed_at
  `lead_score`          TINYINT UNSIGNED DEFAULT 50, -- 1 to 100 Lead Quality Score
  `priority`            ENUM('Low','Medium','High','Urgent') NOT NULL DEFAULT 'Medium',
  `preferred_channel`   ENUM('Call','WhatsApp','Email','SMS') NOT NULL DEFAULT 'Call',
  KEY `idx_adm_enq_next_follow_up` (`next_follow_up_date`, `status`),
  KEY `idx_adm_enq_priority` (`priority`)
  ```

---

### GAP-03: Offer Response Timestamps on `adm_allotments`
- **Feature Detail:** Missing / Audit Gap
- **Affected Table:** `adm_allotments`
- **Description:**  
  `adm_allotments` captures `offer_issued_at` and `offer_expires_at`, but when a parent clicks "Accept Offer" or "Decline Offer" on the portal, there are no dedicated timestamp or reason fields.
- **Recommended Additions:**
  ```sql
  `accepted_at`        TIMESTAMP NULL,
  `declined_at`        TIMESTAMP NULL,
  `declined_reason`    TEXT NULL,
  `allotment_round`    TINYINT UNSIGNED NOT NULL DEFAULT 1, -- Round 1, Round 2, Round 3 counseling
  ```

---

### GAP-04: Refund Disbursement Mode & Bank Details on `adm_withdrawals`
- **Feature Detail:** Missing / Finance Integration
- **Affected Table:** `adm_withdrawals`
- **Description:**  
  When an admission is cancelled and refund approved, Finance must disburse funds. `adm_withdrawals` captures `refund_status` and `refund_eligible_amount`, but lacks payment instrument tracking and parent bank account details.
- **Recommended Additions:**
  ```sql
  `refund_mode`            ENUM('Bank_Transfer','Cheque','Payment_Gateway_Reversal','Cash') NULL,
  `refund_transaction_ref` VARCHAR(100) NULL, -- Bank UTR number or gateway refund ID
  `beneficiary_name`       VARCHAR(100) NULL,
  `bank_name`              VARCHAR(100) NULL,
  `bank_account_no`        VARCHAR(30) NULL,
  `bank_ifsc_code`         VARCHAR(15) NULL,
  ```

---

### GAP-05: Multi-Department Institutional Clearance on `adm_transfer_certificates`
- **Feature Detail:** Missing / Institutional Governance
- **Affected Table:** `adm_transfer_certificates`
- **Description:**  
  `adm_transfer_certificates` validates fee clearance via `fees_cleared TINYINT(1)`. However, K-12 schools mandate clearance from multiple departments before TC issuance: Library (unreturned books), Sports/Hostel (equipment/room handover), and Laboratory (apparatus breakage).
- **Recommended Additions:**
  ```sql
  `library_cleared`        TINYINT(1) NOT NULL DEFAULT 0,
  `hostel_cleared`         TINYINT(1) NOT NULL DEFAULT 1, -- 1 if day scholar
  `laboratory_cleared`     TINYINT(1) NOT NULL DEFAULT 1,
  `sports_cleared`         TINYINT(1) NOT NULL DEFAULT 1,
  `clearance_remarks`      TEXT NULL,
  ```

---

### GAP-06: Secondary Subject & Stream Selection in `adm_applications`
- **Feature Detail:** Missing / Academic Workflow
- **Affected Table:** `adm_applications`
- **Description:**  
  For high school admissions (Class 9 to 12), schools require applicants to select Academic Stream (Science, Commerce, Humanities) and optional language subjects (Hindi, Sanskrit, French, German, Computer Science). Storing only `class_applied_id` forces staff to collect subject choices manually on paper.
- **Recommended Additions:**
  ```sql
  `stream_id`              INT UNSIGNED NULL, -- FK to sch_streams (Science, Commerce, Arts)
  `second_language_id`     INT UNSIGNED NULL, -- FK to sys_dropdown_table
  `third_language_id`      INT UNSIGNED NULL, -- FK to sys_dropdown_table
  `optional_subjects_json` JSON NULL,         -- Array of selected subject IDs
  ```
Brij - Not applied as we will connect User Profile Module with this Module too collect above info.

---

### GAP-07: Campus Transport & Hostel Facility Opt-in at Application
- **Feature Detail:** Missing / Cross-Module Operational Gap
- **Affected Table:** `adm_applications`
- **Description:**  
  Parents deciding on school admission invariably require school bus transport or boarding hostel facilities. Capturing this early allows the school to evaluate bus route capacities before confirming admissions.
- **Recommended Additions:**
  ```sql
  `requires_transport`      TINYINT(1) NOT NULL DEFAULT 0,
  `transport_route_id`      INT UNSIGNED NULL,  -- FK to trp_routes.id
  `pickup_stop_id`          INT UNSIGNED NULL,  -- FK to trp_stops.id
  `requires_hostel`         TINYINT(1) NOT NULL DEFAULT 0,
  `hostel_room_type`        ENUM('Single','Double','Dormitory') NULL,
  ```

---

## 3. Missing Relational Tables & Structural Enhancements

These are high-priority database tables that should be introduced into the schema to support advanced workflows and replace unstructured JSON blobs.

### NEW-01: `adm_application_document_versions` (KYC Audit & Re-upload History)
- **Feature Detail:** Missing Table / Enhancement
- **Problem Statement:**  
  `adm_application_documents` has a unique constraint `uq_adm_doc_app_checklist (application_id, checklist_item_id)`. If an uploaded certificate is rejected by the verification officer and the parent uploads a new scan, overwriting the record destroys the rejection remarks, previous file reference, and timestamp history.
- **Proposed Table Structure:**
  ```sql
  CREATE TABLE IF NOT EXISTS `adm_application_document_versions` (
    `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `application_document_id` BIGINT UNSIGNED NOT NULL, -- FK → adm_application_documents
    `media_id`               INT UNSIGNED NOT NULL,    -- FK → sys_media.id
    `version_number`         TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `verification_status`    ENUM('Pending','Verified','Rejected') NOT NULL,
    `verification_remarks`   TEXT NULL,
    `verified_by`            INT UNSIGNED NULL,        -- FK → sys_users.id
    `verified_at`            TIMESTAMP NULL,
    `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_adm_doc_ver_parent` (`application_document_id`),
    CONSTRAINT `fk_adm_doc_ver_doc_id` FOREIGN KEY (`application_document_id`) REFERENCES `adm_application_documents` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Historical audit log of re-uploaded application documents';
  ```

---

### NEW-02: `adm_interview_slots` (Structured Panel & Time-Slot Booking)
- **Feature Detail:** Enhancement
- **Problem Statement:**  
  Currently, `interview_scheduled_at`, `interview_venue`, and `interview_score` are flat columns directly on `adm_applications`. This prevents schools from publishing calendar time slots, assigning multi-member interview panels, or allowing parents to select preferred interview time slots online.
- **Proposed Table Structure:**
  ```sql
  -- -------------------------------------------------------------------------------------------------------------------------------
  -- This Table will define interview slots for a particular admission cycle and class.
  -- -------------------------------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `adm_interview_slots` (
    `id`                 MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `admission_cycle_id` SMALLINT UNSIGNED NOT NULL, -- FK → adm_admission_cycles
    `class_id`           INT UNSIGNED NOT NULL,      -- FK → sch_classes
    `slot_date`          DATE NOT NULL,
    `start_time`         TIME NOT NULL,
    `end_time`           TIME NOT NULL,
    `venue`              VARCHAR(100) NOT NULL,
    `panelist_ids_json`  JSON NULL,                  -- Array of sys_users.id
    `max_candidates`     TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `booked_candidates`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `status`             ENUM('Available','Booked','Completed','Blocked','Cancelled') NOT NULL DEFAULT 'Available',
    `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`         INT UNSIGNED NOT NULL, -- FK → sys_users.id
    `created_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`         TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_adm_int_slot_cycle_date_time` (`admission_cycle_id`, `class_id`, `slot_date`, `start_time`, `end_time`),
    KEY `idx_adm_int_slot_cycle` (`admission_cycle_id`, `class_id`, `slot_date`)
    CONSTRAINT `chk_adm_int_max_candidate_booked_candidates` CHECK (`booked_candidates` <= `max_candidates` AND `booked_candidates` >= 0),
    CONSTRAINT `chk_adm_int_slot_end_time` CHECK (`end_time` > `start_time`),
    CONSTRAINT `fk_adm_int_slot_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Bookable interview time slots and panel assignments';
  ```


-- -------------------------------------------------------------------------------------------------------------------------------
-- This is a Child table for `adm_interview_slots`, which will capture list of all applicants for a particular interview slot,
-- and remove the same when the applicant is assigned to a interview slot.
-- -------------------------------------------------------------------------------------------------------------------------------
```sql
-- -------------------------------------------------------------------------------------------------------------------------------
-- This Table will have all applications for a particular interview slot. when an interview slot is assigned to an applicant, 
-- the slot will be marked as `Booked` and `booked_at` should be updated. Also `booked_canddates` in `adm_interview_slots` table will be incremented.
-- If the `booked_candidates` = `max_candidates`, then the slot should be marked as `Full`, till then the status should be `Available`.
-- --------------------------------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `adm_interview_slots_items` (
    `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `interview_slot_id`      MEDIUMINT UNSIGNED NOT NULL, -- FK → adm_interview_slots
    `application_id`         BIGINT UNSIGNED NOT NULL, -- FK → adm_applications
    `parent_comments`        text         DEFAULT NULL, -- "Want to discuss math performance"
    `status`                 ENUM('Available', 'Booked', 'Cancelled', 'No-Show', 'Completed', 'Rescheduled') NOT NULL DEFAULT 'Available',
    `booked_at`              TIMESTAMP    NULL DEFAULT NULL,              -- when the booking was placed
    `attended`               tinyint(1)   DEFAULT NULL,                   -- 1=attended, 0=no-show, NULL=meeting hasn't happened yet
    `meeting_notes`          text         DEFAULT NULL,                   -- post-meeting notes captured by teacher
    -- Cancelled  Re-Scheduled
    `cancelled_at`           timestamp    NULL DEFAULT NULL,              -- when it was cancelled (NULL while CONFIRMED)
    `cancelled_by`           INT UNSIGNED NOT NULL,                       -- FK → sys_users.id
    `cancel_reason`          varchar(255) DEFAULT NULL,                   -- e.g. 'Parent unavailable'
    `rescheduled_at`         timestamp    NULL DEFAULT NULL,              -- when it was rescheduled
    `reschedule_by`          INT UNSIGNED NOT NULL,                       -- FK → sys_users.id
    `reschedule_reason`      varchar(255) DEFAULT NULL,                   -- e.g. 'Parent requested new time'
    `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_by`             INT UNSIGNED NOT NULL, -- FK → sys_users.id
    `updated_at`             TIMESTAMP NULL DEFAULT NULL,                  -- when last updated
    `deleted_at`             TIMESTAMP NULL DEFAULT NULL,                  -- when deleted
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_adm_int_slot_item_app` (`application_id`, `interview_slot_id`),
    CONSTRAINT `fk_adm_int_slot_item_slot` FOREIGN KEY (`interview_slot_id`) REFERENCES `adm_interview_slots` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_item_cancelled_by` FOREIGN KEY (`cancelled_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_item_reschedule_by` FOREIGN KEY (`reschedule_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_item_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_adm_int_slot_item_app` FOREIGN KEY (`application_id`) REFERENCES `adm_applications` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='List of applicants for each interview slot';
```
---

### NEW-02.1: `adm_application_interviews` (Interview Log for History)
- **Feature Detail:** Enhancement / DB Normalization
- **Problem Statement:**  
  `adm_applications` has interview_scheduled_at/venue/notes columns. This is insufficient for schools that conduct multiple rounds of interviews (e.g., Screening + Final) or require detailed feedback tracking per panel member.
- **Proposed Table Structure:**
  ```sql
  CREATE TABLE IF NOT EXISTS `adm_application_interviews` (
    `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `application_id`         BIGINT UNSIGNED NOT NULL, -- FK → adm_applications
    `interview_slot_id`      MEDIUMINT UNSIGNED NULL,  -- FK to adm_interview_slots (if linked to a booking)
    `round_number`           TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `interview_type`         ENUM('Screening','Academic','Final','Behavioral') NOT NULL,
    `scheduled_at`           TIMESTAMP NOT NULL,       -- Actual scheduled time
    `actual_start_time`      DATETIME NULL,            -- Actual start time (if different from scheduled)
    `actual_end_time`        DATETIME NULL,            -- Actual end time
    `panelist_ids_json`      JSON NULL,                -- Array of sys_users.id (actual panelists)
    `venue`                  VARCHAR(100) NOT NULL,    -- Actual venue
    `notes_json`             JSON NULL,                -- Detailed feedback per panel member or overall
    `overall_status`         ENUM('Completed','Absent','Cancelled') NOT NULL,
    `created_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_adm_int_app_id` (`application_id`),
    KEY `idx_adm_int_slot_id` (`interview_slot_id`),
    CONSTRAINT `fk_adm_int_app` FOREIGN KEY (`application_id`) REFERENCES `adm_applications` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Detailed log of interviews conducted for each application';
  ```

---

### NEW-03: `adm_age_criteria_rules` (Relational Normalization of `age_rules_json`)
- **Feature Detail:** Enhancement / DB Normalization
- **Problem Statement:**  
  `adm_admission_cycles.age_rules_json` stores class age minimums/maximums as unstructured JSON (`{"1":{"min":5,"max":7}}`). JSON fields cannot enforce foreign key integrity against `sch_classes` or prevent negative age constraints at the database engine level.
- **Proposed Table Structure:**
  ```sql
  CREATE TABLE IF NOT EXISTS `adm_age_criteria_rules` (
    `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `admission_cycle_id` SMALLINT UNSIGNED NOT NULL, -- FK → adm_admission_cycles
    `class_id`           INT UNSIGNED NOT NULL,      -- FK → sch_classes
    `min_age_years`      DECIMAL(4,2) NOT NULL,      -- e.g. 5.50 Years
    `max_age_years`      DECIMAL(4,2) NOT NULL,      -- e.g. 7.00 Years
    `created_at`         TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_adm_age_cycle_class` (`admission_cycle_id`, `class_id`),
    CONSTRAINT `fk_adm_age_cycle_id` FOREIGN KEY (`admission_cycle_id`) REFERENCES `adm_admission_cycles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_adm_age_class_id` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Normalized relational class age eligibility criteria';
  ```

---

### NEW-04: `adm_quota_conversion_rules` (De-reservation of Unfilled Quota Seats)
- **Feature Detail:** Statutory / Operational Enhancement
- **Problem Statement:**  
  Schools reserve quota seats (e.g., Management, NRI, Staff Ward). If these seats remain unfilled after Round 1 or Round 2, institutional policy dictates de-reserving and converting them into the General quota pool before school reopens. No mechanism exists to govern seat conversion.
- **Proposed Table Structure:**
  ```sql
  CREATE TABLE IF NOT EXISTS `adm_quota_conversion_logs` (
    `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `admission_cycle_id` SMALLINT UNSIGNED NOT NULL,
    `class_id`           INT UNSIGNED NOT NULL,
    `source_quota`       ENUM('Management','NRI','Staff_Ward','EWS') NOT NULL,
    `target_quota`       ENUM('General') NOT NULL DEFAULT 'General',
    `seats_transferred`  SMALLINT UNSIGNED NOT NULL,
    `authorized_by`      INT UNSIGNED NOT NULL,      -- FK → sys_users.id (Principal)
    `conversion_date`    DATE NOT NULL,
    `remarks`            TEXT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Audit log of de-reserved quota seat transfers';
  ```

---

## 4. Statutory & Institutional Compliance Gaps

### COMP-01: National Academic Depository & UDISE+ Export Schema
- **Feature Detail:** Statutory Enhancement
- **Description:**  
  Under the Indian Ministry of Education guidelines, all newly admitted students must be registered in the **UDISE+ portal** and assigned a **Permanent Academic Account (APAAR ID / ABC ID)**.
- **Current Gap:** While `apaar_id` was added to `adm_applications` in V2, statutory fields required for government UDISE+ registration are missing:
  - `udise_student_pen` (Permanent Education Number, 11-digit code).
  - `domicile_state_id` (State of origin).
  - `minority_group_id` (Linguistic / Religious minority indicator).
  - `bpl_card_no` (Below Poverty Line indicator for RTE/EWS verification).
  - `cwsn_facility_json` (Children With Special Needs accommodations: Braille, Ramp, Wheelchair).

---

### COMP-02: Formal RTE 25% Lottery / Randomizer Protocol
- **Feature Detail:** Statutory Compliance
- **Description:**  
  Under Section 12(1)(c) of the Right to Education (RTE) Act 2009, private unaided schools must allocate 25% of seats at the entry level to disadvantaged groups via an **open, transparent, government-supervised lottery system**.
- **Current Gap:** The module treats `RTE` as a standard quota subject to merit score ranking. Ranking RTE applicants by entrance exam or prior marks is illegal under RTE Section 13.
- **Recommended Solution:**
  - Introduce an automated **Cryptographic Lottery Selection Engine** (`LotteryDrawService`) for RTE quota candidates.
  - Generates verifiable random seed hashes (`lottery_seed_hash`) to prove zero administrative tampering to government inspectors.

---

## 5. Advanced Feature Enhancements

### ENH-01: WhatsApp Business API Multi-Touch CRM Integration
- **Feature Detail:** Modern UX Enhancement
- **Description:**  
  Email and SMS open rates for prospective parents are below 20%, whereas WhatsApp engagement exceeds 85%.
- **Proposed Architecture:**
  - Direct integration with Meta Cloud WhatsApp API.
  - Automated WhatsApp notifications dispatched on:
    1. Enquiry Acknowledgement with brochure PDF attachment.
    2. Scheduled Follow-up meeting reminders 2 hours prior.
    3. Document Re-upload request with instant camera upload link.
    4. Offer Letter PDF with embedded "Click to Pay Admission Fee" CTA button.

---

### ENH-02: AI-Powered OCR for KYC Document Pre-Filling
- **Feature Detail:** Efficiency & Error Reduction
- **Description:**  
  Typing student birth certificate details and Aadhaar numbers leads to frequent human error.
- **Proposed Capability:**
  - When a parent uploads a Birth Certificate or Aadhaar Card in Step 6, an integrated vision AI pipeline (Google Cloud Document AI / AWS Textract) automatically extracts:
    - Child's Full Name
    - Date of Birth
    - Father's & Mother's Names
    - Registration / Certificate Number
  - Automatically highlights mismatches between typed form fields and OCR-extracted document text for verification officers.

---

### ENH-03: Multi-Round Admission Counseling & Waiting List Rollover
- **Feature Detail:** Advanced Workflow
- **Description:**  
  Large schools operate admissions in multiple sequential rounds (Round 1: Siblings & Staff; Round 2: General Merit; Round 3: Mop-up).
- **Proposed Architecture:**
  - Introduce `admission_round` in `adm_merit_lists` and `adm_allotments`.
  - When Round 1 offer deadlines elapse, an automated console worker closes Round 1, aggregates remaining vacancies, and automatically rolls over waitlisted candidates to Round 2 allotments.

---

### ENH-04: Prospective Student Entrance CBT (Computer-Based Testing) Engine
- **Feature Detail:** Platform Integration
- **Description:**  
  Instead of linking to third-party Google Forms or external websites (`online_test_link`), integrate directly with the LMS / Testing module (`Modules\Testing`).
- **Proposed Capability:**
  - Candidates log in to a secure online testing portal using their `application_no` and an OTP sent to their mobile.
  - Timed examination with auto-evaluation for MCQ sections, automatically pushing final scores into `adm_entrance_test_candidates.marks_obtained`.

---

## Actionable Engineering Implementation Priority Matrix

| Priority | Item ID | Category | Summary of Finding / Enhancement | Target Effort |
|:---:|---|---|---|:---:|
| **P0 (Blocker)** | **BUG-01** | Schema Bug | Correct foreign key column mismatches in `adm_applications` (`student_religion_id`, etc.). | 1 Hour |
| **P0 (Blocker)** | **BUG-02** | Schema Bug | Add missing foreign key `fk_adm_et_media_id` in `adm_entrance_tests`. | 1 Hour |
| **P0 (Blocker)** | **BUG-03** | Schema Bug | Fix spelling of `academic_percentage`, `test_percentage`, `interview_percentage`. | 1 Hour |
| **P1 (High)** | **GAP-01** | Audit | Uncomment and enforce `created_by` / `updated_by` across all 20 tables. | 2 Hours |
| **P1 (High)** | **GAP-02** | Performance | Add `next_follow_up_date`, `lead_score`, and `priority` to `adm_enquiries`. | 3 Hours |
| **P1 (High)** | **GAP-03** | Audit | Add `accepted_at`, `declined_at`, `declined_reason` to `adm_allotments`. | 2 Hours |
| **P1 (High)** | **GAP-04** | Finance | Add refund payment mode, UTR, and bank details to `adm_withdrawals`. | 3 Hours |
| **P1 (High)** | **GAP-05** | Governance | Add Library, Lab, Sports, and Hostel clearance checks to `adm_transfer_certificates`. | 4 Hours |
| **P1 (High)** | **NEW-01** | Architecture | Create `adm_application_document_versions` table for KYC re-upload tracking. | 6 Hours |
| **P2 (Medium)** | **GAP-06** | Academic | Add Stream ID, 2nd language, and 3rd language choices to `adm_applications`. | 4 Hours |
| **P2 (Medium)** | **GAP-07** | Operations | Add Transport route/pickup and Hostel opt-in flags to `adm_applications`. | 4 Hours |
| **P2 (Medium)** | **COMP-01** | Compliance | Add UDISE+ and Government PEN fields to student demographics. | 4 Hours |
| **P2 (Medium)** | **COMP-02** | Compliance | Implement RTE Cryptographic Lottery Engine for entry-level admissions. | 1 Sprint |
| **P3 (Future)** | **ENH-01** | Feature | Integrate WhatsApp Business Cloud API for automated parent journey notifications. | 1 Sprint |
| **P3 (Future)** | **ENH-02** | AI / Vision | Implement AI Document OCR for auto-filling and KYC cross-verification. | 2 Sprints |
