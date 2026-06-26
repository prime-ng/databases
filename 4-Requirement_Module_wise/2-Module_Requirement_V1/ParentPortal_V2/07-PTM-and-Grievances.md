# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 07: PTM & Grievances (Deep Technical)

---

## 1. Executive Summary
This feature manages two-way communication: formal meetings (PTM - Parent Teacher Meetings) and issue resolution (Complaints/Grievances). Due to high concurrency during PTM bookings, strict database locks and overlap validations are enforced.

## 2. Core Components
- `ParentPtmController.php`
- `ParentComplaintController.php`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: PTM Slot Booking Engine (`ParentPtmController`)
- **Visibility:** Parents see upcoming PTM schedules created by the school for their active child's class. Only events where `is_active=1` and `event_start_date` is upcoming are visible.
- **Booking Window Validation:** If the event has `booking_window_start` and `booking_window_end` defined, the system completely blocks slot booking outside of this timeframe.
- **Strict Concurrency Control (Atomic Locks):** 
  - Multiple parents might try to book the exact same 10:00 AM slot for the Class Teacher.
  - The controller uses `DB::transaction()` and `$slot->lockForUpdate()` to physically lock the MySQL row.
  - Checks if `booked_count >= capacity`. If true, rejects the booking and sets status to `FULL`.
- **Overlap Validation (Cross-Event):**
  - A parent cannot book a slot if the `slot_start` and `slot_end` physically overlaps with *any other confirmed booking* they have for this child (even with a different teacher).
  - Also restricts a student from having more than one slot in the exact same event.
- **Blockout Checks:** Uses `isSlotBlockedByBlockout()` to verify if the teacher suddenly marked themselves unavailable (e.g., lunch break).
- **Notification Trigger:** Upon successful booking, immediately fires a `PTM_BOOKED` event via the Notification Module to alert both the parent and the teacher.

### FR-02: Grievance Management (`ParentComplaintController`)
- **Ticket Auto-Generation:** Uses `DB::beginTransaction()` and `lockForUpdate()` to safely generate sequential ticket numbers like `CMP-2026-000001`.
- **Anonymous Complaints:**
  - Includes an `is_anonymous` flag.
  - If true, the system resolves the complainant type from system dropdowns to "Anonymous" and deliberately sets `complainant_user_id` and `complainant_contact` to `null` in the DB, ensuring complete privacy even from DB admins.
- **Media Upload:** Supports uploading photographic evidence (e.g., broken desk) via `$request->file('complaint_img')` which is piped to Spatie Media Library collection `complaint_img`.
- **Target Resolution:** Resolves exactly who or what the complaint is about via `target_table_name` and `target_selected_id`.

---

## 4. Acceptance Criteria
- **Given** Teacher A has a slot at 10:00 AM with capacity=1, **When** Parent X and Parent Y both click 'Book' at the exact same millisecond, **Then** the database lock ensures Parent X gets the slot and Parent Y receives an error "This slot is already fully booked."
